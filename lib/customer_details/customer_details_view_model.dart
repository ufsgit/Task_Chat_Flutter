import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api.dart';
import '../api/authenticated_client.dart';
import '../login_page/token_storage.dart';
import '../today/today_model.dart';
import '../update_status/status_update_result.dart';
import 'customer_details_model.dart';
import 'widgets/customer_header_card.dart';

/// Represents a brochure document returned by `/api/brochures`.
class BrochureItem {
  final String url;
  final String title;
  final String? description;
  final String? fileName;
  final String? mimeType;

  const BrochureItem({
    required this.url,
    required this.title,
    this.description,
    this.fileName,
    this.mimeType,
  });
}

/// ViewModel managing state, status updates, notes, and deletion for Customer Details screen.
class CustomerDetailsViewModel extends ChangeNotifier {
  final http.Client _client;
  final bool _isInternalClient;
  final TokenStorage? tokenStorage;
  CustomerDetailsModel customer;

  bool _isDeleting = false;
  String? _deleteError;
  bool _isUpdating = false;
  String? _updateError;
  bool _isFetching = false;
  String? _fetchError;

  CustomerDetailsViewModel({
    required this.customer,
    http.Client? client,
    this.tokenStorage,
  }) : _client = client ?? AuthenticatedClient(),
       _isInternalClient = client == null;

  http.Client get client => _client;
  bool get isDeleting => _isDeleting;
  String? get deleteError => _deleteError;
  bool get isUpdating => _isUpdating;
  String? get updateError => _updateError;
  bool get isFetching => _isFetching;
  String? get fetchError => _fetchError;

  /// Fetches latest details for this customer/booking from the backend API.
  Future<bool> fetchCustomerDetails() async {
    if (customer.id.isEmpty) {
      _fetchError = 'Failed to update';
      return false;
    }
    _isFetching = true;
    _fetchError = null;
    notifyListeners();

    try {
      final headers = await (tokenStorage ?? TokenStorage()).authHeaders();
      final uri = Uri.parse('${ApiConfig.bookings}/${customer.id}');

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final rawData = decoded is Map<String, dynamic>
            ? (decoded['data'] ??
                  decoded['booking'] ??
                  decoded['item'] ??
                  decoded)
            : null;

        if (rawData is Map<String, dynamic>) {
          customer = CustomerDetailsModel.fromBooking(
            BookingModel.fromJson(rawData),
          );
          _fetchError = null;
          notifyListeners();
          return true;
        } else {
          _fetchError = 'Failed to update';
        }
      } else {
        _fetchError = 'Failed to update';
      }
    } catch (_) {
      _fetchError = 'Failed to update';
    } finally {
      _isFetching = false;
      notifyListeners();
    }
    return false;
  }

  /// Deletes customer booking from backend API (`DELETE /api/bookings/:id`).
  Future<bool> deleteCustomer() async {
    _isDeleting = true;
    _deleteError = null;
    notifyListeners();

    try {
      final headers = await (tokenStorage ?? TokenStorage()).authHeaders();
      final uri = Uri.parse('${ApiConfig.bookings}/${customer.id}');

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        String msg = 'Failed to delete customer (${response.statusCode})';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['error'] != null) {
              msg = decoded['error'].toString();
            } else if (decoded['message'] != null) {
              msg = decoded['message'].toString();
            }
          }
        } catch (_) {}
        _deleteError = msg;
        return false;
      }
    } catch (e) {
      _deleteError = 'Connection error';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Updates customer booking on backend API (`PUT /api/bookings/:id`).
  Future<bool> updateCustomer({
    String? name,
    String? phoneNumber,
    String? address,
    String? notes,
    String? status,
    List<String>? documents,
  }) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();

    try {
      final headers = await (tokenStorage ?? TokenStorage()).authHeaders(
        includeContentType: true,
      );
      final uri = Uri.parse('${ApiConfig.bookings}/${customer.id}');

      final updatedName = name ?? customer.name;
      final updatedPhone = phoneNumber ?? customer.phoneNumber;
      final updatedAddress =
          address ??
          (customer.addressLine2.isNotEmpty
              ? '${customer.addressLine1}, ${customer.addressLine2}'
              : customer.addressLine1);
      final updatedNotes = notes ?? customer.notes;
      final updatedStatus = status ?? customer.status;
      final updatedDocs = documents ?? customer.documents;

      final body = jsonEncode({
        'name': updatedName,
        'mobile': updatedPhone,
        'address': updatedAddress,
        'notes': updatedNotes,
        'status': updatedStatus.toUpperCase(),
        'documents': updatedDocs,
      });

      final response = await _client
          .put(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        customer = customer.copyWith(
          name: updatedName,
          phoneNumber: updatedPhone,
          addressLine1: updatedAddress,
          addressLine2: '',
          notes: updatedNotes,
          status: updatedStatus,
          documents: updatedDocs,
        );
        notifyListeners();
        return true;
      } else {
        String msg = 'Failed to update contact (${response.statusCode})';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['error'] != null) {
              msg = decoded['error'].toString();
            } else if (decoded['message'] != null) {
              msg = decoded['message'].toString();
            }
          }
        } catch (_) {}
        _updateError = msg;
        return false;
      }
    } catch (e) {
      _updateError = 'Connection error';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Updates the status and optional schedule date of the customer.
  void updateStatus(String newStatus, {String? scheduleDate}) {
    final wasScheduled =
        newStatus.toLowerCase() == 'scheduled' || customer.hasBeenScheduled;
    customer = customer.copyWith(
      status: newStatus,
      scheduleDate: scheduleDate ?? customer.scheduleDate,
      hasBeenScheduled: wasScheduled,
    );
    notifyListeners();
  }

  /// Applies a full status update result from Update Status page.
  void applyUpdate(StatusUpdateResult result) {
    final wasScheduled =
        result.status.toLowerCase() == 'scheduled' || customer.hasBeenScheduled;
    customer = customer.copyWith(
      status: result.status,
      scheduleDate: result.scheduleDate.isNotEmpty
          ? result.scheduleDate
          : customer.scheduleDate,
      notes: result.notes.isNotEmpty ? result.notes : customer.notes,
      staffNotes: result.staffNotes.isNotEmpty
          ? result.staffNotes
          : customer.staffNotes,
      documents: result.documents.isNotEmpty
          ? result.documents
          : customer.documents,
      branchHeadName: result.branchManager ?? customer.branchHeadName,
      hasBeenScheduled: wasScheduled,
    );
    notifyListeners();
  }

  /// Updates notes on the customer model.
  void updateNotes(String newNotes) {
    customer = customer.copyWith(notes: newNotes);
    notifyListeners();
  }

  /// Formats all available customer details into structured text for WhatsApp sharing.
  String formatCustomerDataForSharing() {
    final buffer = StringBuffer();
    buffer.writeln('*Customer Details*');
    if (customer.name.trim().isNotEmpty) {
      buffer.writeln('*Name:* ${customer.name.trim()}');
    }
    if (customer.phoneNumber.trim().isNotEmpty) {
      buffer.writeln('*Phone:* ${customer.phoneNumber.trim()}');
    }
    if (customer.status.trim().isNotEmpty) {
      buffer.writeln('*Status:* ${customer.status.trim()}');
    }
    if (customer.scheduleDate != null &&
        customer.scheduleDate!.trim().isNotEmpty) {
      buffer.writeln('*Scheduled Date:* ${customer.formattedScheduleDate}');
    }
    final addressParts = [
      customer.addressLine1.trim(),
      customer.addressLine2.trim(),
    ].where((p) => p.isNotEmpty).join(', ');
    if (addressParts.isNotEmpty) {
      buffer.writeln('*Address:* $addressParts');
    }
    if (customer.mapLink != null && customer.mapLink!.trim().isNotEmpty) {
      buffer.writeln('*Location Map:* ${customer.mapLink!.trim()}');
    }
    if (customer.inquiry.trim().isNotEmpty) {
      buffer.writeln('*Enquiry:* ${customer.inquiry.trim()}');
    }
    if (customer.notes.trim().isNotEmpty) {
      buffer.writeln('*Notes:* ${customer.notes.trim()}');
    }
    if (customer.staffNotes.trim().isNotEmpty) {
      buffer.writeln('*Staff Notes:* ${customer.staffNotes.trim()}');
    }
    if (customer.branchHeadName != null &&
        customer.branchHeadName!.trim().isNotEmpty) {
      buffer.writeln('*Branch Manager:* ${customer.branchHeadName!.trim()}');
    }
    return buffer.toString().trim();
  }

  /// Shares all customer information as text, allowing staff to select recipients in WhatsApp or share sheet.
  Future<bool> shareDataToWhatsApp({
    Future<void> Function(String? phone, {String? text})? whatsAppLauncher,
    Future<void> Function(String text)? shareLauncher,
  }) async {
    final text = formatCustomerDataForSharing();
    if (text.isEmpty) return false;

    if (shareLauncher != null) {
      await shareLauncher(text);
      return true;
    }

    if (whatsAppLauncher != null) {
      await whatsAppLauncher(null, text: text);
      return true;
    }

    final encodedText = Uri.encodeComponent(text);
    final whatsappUri = Uri.parse('whatsapp://send?text=$encodedText');

    try {
      final launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
      if (launched) return true;
    } catch (_) {}

    try {
      await Share.share(text, subject: 'Customer Details - ${customer.name}');
      return true;
    } catch (_) {
      return false;
    }
  }

  static Directory get _brochureShareDir => Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}brochure_share',
  );

  static String _urlCacheKey(String url) {
    int hash = 0x811c9dc5;
    for (final codeUnit in url.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  static String? _mimeTypeFromName(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  static void _syncBrochureCache(List<BrochureItem> activeItems) {
    if (kIsWeb) return;
    try {
      final dir = _brochureShareDir;
      if (!dir.existsSync()) return;
      final validKeys = activeItems.map((e) => _urlCacheKey(e.url)).toSet();
      for (final entity in dir.listSync()) {
        final name = entity.uri.pathSegments
            .where((s) => s.isNotEmpty)
            .lastOrNull;
        if (name == null || !validKeys.contains(name)) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  /// Fetches brochure items (with metadata like title/filename) from [ApiConfig.brochure].
  Future<List<BrochureItem>> fetchBrochureItems() async {
    try {
      final raw = ApiConfig.brochure.trim();
      final url = raw.startsWith('http')
          ? raw
          : '${ApiConfig.baseUrl}/${raw.replaceFirst(RegExp(r'^/'), '')}';

      debugPrint('>>> [Brochure] Fetching brochures from: $url');
      final uri = Uri.parse(url);
      final headers = await (tokenStorage ?? TokenStorage()).authHeaders();
      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint(
        '<<< [Brochure] Brochures status: ${response.statusCode}, body: ${response.body}',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          final dynamic decoded = jsonDecode(response.body);
          final extracted = _extractBrochureItems(decoded);
          _syncBrochureCache(extracted);
          if (extracted.isNotEmpty) {
            debugPrint(
              '<<< [Brochure] Extracted URLs from API: ${extracted.map((e) => e.url).toList()}',
            );
            return extracted;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching brochure config: $e');
    }

    return [];
  }

  /// Fetches brochure document URL(s) from the [ApiConfig.brochure] (`/api/brochures`) endpoint.
  /// Reads `file_url` (or `shareUrl` / `fileUrl` / etc.) and supports multiple URLs.
  Future<List<String>> fetchBrochureUrls() async {
    final items = await fetchBrochureItems();
    return items.map((e) => e.url).toList();
  }

  /// Extracts one or more [BrochureItem] objects from the decoded API response.
  List<BrochureItem> _extractBrochureItems(dynamic decoded) {
    final List<BrochureItem> items = [];
    final Set<String> seenUrls = {};
    String? explicitBaseUrl;
    if (decoded is Map) {
      final base =
          decoded['shareBaseUrl'] ?? decoded['baseUrl'] ?? decoded['base_url'];
      if (base is String && base.trim().isNotEmpty) {
        explicitBaseUrl = base.trim();
      }
    }

    String deriveTitle(String url, Map? meta) {
      final t = meta?['title']?.toString().trim();
      if (t != null && t.isNotEmpty) return t;
      final orig = meta?['original_name']?.toString().trim();
      if (orig != null && orig.isNotEmpty) return orig;
      final fn = meta?['file_name']?.toString().trim();
      if (fn != null && fn.isNotEmpty) return fn;
      final segs = Uri.tryParse(url)?.pathSegments;
      if (segs != null && segs.isNotEmpty && segs.last.trim().isNotEmpty) {
        return segs.last.trim();
      }
      return 'Brochure';
    }

    void addUrlString(String rawUrl, [Map? meta]) {
      final normalized = _normalizeUrl(rawUrl, explicitBaseUrl);
      if (seenUrls.add(normalized)) {
        final origName =
            meta?['original_name']?.toString().trim() ??
            meta?['file_name']?.toString().trim();
        final segs = Uri.tryParse(normalized)?.pathSegments;
        final fallbackName = (segs != null && segs.isNotEmpty)
            ? segs.last
            : null;
        items.add(
          BrochureItem(
            url: normalized,
            title: deriveTitle(normalized, meta),
            description: meta?['description']?.toString().trim(),
            fileName: (origName != null && origName.isNotEmpty)
                ? origName
                : fallbackName,
            mimeType: meta?['mime_type']?.toString().trim(),
          ),
        );
      }
    }

    void addItem(dynamic item, [Map? meta]) {
      if (item == null) return;
      if (item is List) {
        for (final sub in item) {
          addItem(sub, meta);
        }
      } else if (item is Map) {
        final target =
            item['file_url'] ??
            item['fileUrl'] ??
            item['shareUrl'] ??
            item['shareUrls'] ??
            item['share_url'] ??
            item['share_urls'] ??
            item['brochureUrl'] ??
            item['brochure_url'] ??
            item['brochure'] ??
            item['brochures'] ??
            item['url'] ??
            item['urls'] ??
            item['docUrl'] ??
            item['documentUrl'] ??
            item['pdfUrl'] ??
            item['link'];

        if (target != null) {
          addItem(target, item);
        } else if (item.containsKey('data')) {
          addItem(item['data'], item);
        }
      } else if (item is String) {
        final trimmed = item.trim();
        if (trimmed.isNotEmpty) {
          if (trimmed.contains(',') && !trimmed.startsWith('data:')) {
            for (final part in trimmed.split(',')) {
              final p = part.trim();
              if (p.isNotEmpty) addUrlString(p, meta);
            }
          } else {
            addUrlString(trimmed, meta);
          }
        }
      }
    }

    if (decoded is Map<String, dynamic>) {
      // Prioritize shareUrl / shareUrls from root
      final shareUrl =
          decoded['shareUrl'] ??
          decoded['shareUrls'] ??
          decoded['share_url'] ??
          decoded['share_urls'];

      if (shareUrl != null) {
        addItem(shareUrl, decoded);
      } else if (decoded.containsKey('data')) {
        addItem(decoded['data'], decoded);
      } else {
        addItem(decoded, decoded);
      }
    } else if (decoded is List) {
      addItem(decoded);
    } else if (decoded is String) {
      addItem(decoded);
    }

    return items;
  }

  String _normalizeUrl(String raw, [String? baseUrl]) {
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final cleanPath = raw.startsWith('/') ? raw : '/$raw';
    final base = (baseUrl != null && baseUrl.isNotEmpty)
        ? (baseUrl.endsWith('/')
              ? baseUrl.substring(0, baseUrl.length - 1)
              : baseUrl)
        : ApiConfig.baseUrl;
    return '$base$cleanPath';
  }

  /// Fetches the primary brochure document URL from the [ApiConfig.brochure] endpoint.
  Future<String?> fetchBrochureUrl() async {
    final urls = await fetchBrochureUrls();
    return urls.isNotEmpty ? urls.first : null;
  }

  /// Takes brochure document(s) from the link(s) configured in [ApiConfig.brochure]
  /// and shares them (single or multiple) with the customer or staff-selected recipients.
  Future<bool> shareBrochureFromLink({
    List<String>? overrideDocUrls,
    String? overrideDocUrl,
    Future<void> Function(List<XFile> files, {String? text})? shareLauncher,
    Future<void> Function(String text)? textShareLauncher,
  }) async {
    final List<String> docUrls =
        overrideDocUrls ??
        (overrideDocUrl != null ? [overrideDocUrl] : await fetchBrochureUrls());

    if (docUrls.isEmpty) {
      return false;
    }

    Directory? shareTempDir;
    if (!kIsWeb) {
      shareTempDir = _brochureShareDir;
      if (!shareTempDir.existsSync()) {
        shareTempDir.createSync(recursive: true);
      }
    }

    // Reuse cached files for unchanged URLs; download any missing ones concurrently
    final results = await Future.wait(
      docUrls.map((docUrl) async {
        try {
          Directory? urlCacheDir;
          if (!kIsWeb && shareTempDir != null) {
            urlCacheDir = Directory(
              '${shareTempDir.path}${Platform.pathSeparator}${_urlCacheKey(docUrl)}',
            );
            if (urlCacheDir.existsSync()) {
              for (final entity in urlCacheDir.listSync()) {
                if (entity is File && entity.lengthSync() > 0) {
                  final cachedName = entity.uri.pathSegments
                      .where((s) => s.isNotEmpty)
                      .lastOrNull ?? 'brochure';
                  debugPrint('>>> [Brochure] Reusing cached file: ${entity.path}');
                  return (
                    file: XFile(
                      entity.path,
                      name: cachedName,
                      mimeType: _mimeTypeFromName(cachedName),
                    ),
                    failedUrl: null as String?,
                  );
                }
              }
            }
          }

          debugPrint('>>> [Brochure] Downloading file from: $docUrl');
          final fileUri = Uri.parse(docUrl);
          final fileResponse = await _client
              .get(fileUri)
              .timeout(const Duration(seconds: 30));
          debugPrint(
            '<<< [Brochure] Download status: ${fileResponse.statusCode}, bytes: ${fileResponse.bodyBytes.length}',
          );

          if (fileResponse.statusCode >= 200 &&
              fileResponse.statusCode < 300 &&
              fileResponse.bodyBytes.isNotEmpty) {
            final pathSeg = fileUri.pathSegments;
            final rawName = pathSeg.isNotEmpty ? pathSeg.last : 'brochure';
            String fileName = rawName;
            String? mimeType = _mimeTypeFromName(rawName);

            if (!rawName.contains('.')) {
              final contentType =
                  fileResponse.headers['content-type']?.toLowerCase() ?? '';
              if (contentType.contains('png')) {
                fileName = '$rawName.png';
                mimeType = 'image/png';
              } else if (contentType.contains('image')) {
                fileName = '$rawName.jpg';
                mimeType = 'image/jpeg';
              } else {
                fileName = '$rawName.pdf';
                mimeType = 'application/pdf';
              }
            }

            final XFile xFile;
            if (kIsWeb) {
              xFile = XFile.fromData(
                fileResponse.bodyBytes,
                name: fileName,
                mimeType: mimeType,
              );
            } else {
              urlCacheDir!.createSync(recursive: true);
              final tempFile = File(
                '${urlCacheDir.path}${Platform.pathSeparator}$fileName',
              );
              tempFile.writeAsBytesSync(fileResponse.bodyBytes, flush: true);
              xFile = XFile(tempFile.path, name: fileName, mimeType: mimeType);
            }
            return (file: xFile, failedUrl: null as String?);
          }
          return (file: null as XFile?, failedUrl: docUrl);
        } catch (e) {
          debugPrint('Error downloading brochure file from $docUrl: $e');
          return (file: null as XFile?, failedUrl: docUrl);
        }
      }),
    );

    final List<XFile> filesToShare = [];
    final List<String> failedUrls = [];
    for (final res in results) {
      if (res.file != null) {
        filesToShare.add(res.file!);
      } else if (res.failedUrl != null) {
        failedUrls.add(res.failedUrl!);
      }
    }

    // If at least one file was downloaded successfully, share via files
    if (filesToShare.isNotEmpty) {
      final String? textWithLinks = failedUrls.isEmpty
          ? null
          : failedUrls.join('\n');

      if (shareLauncher != null) {
        await shareLauncher(filesToShare, text: textWithLinks);
      } else {
        await Share.shareXFiles(filesToShare, text: textWithLinks);
      }
      return true;
    }

    // No fallbacks: return false if document(s) could not be loaded
    return false;
  }

  /// Shares a brochure PDF file to the customer via WhatsApp/Share sheet.
  Future<bool> shareBrochurePdf({
    String? filePath,
    XFile? xFile,
    String? text,
    Future<void> Function(List<XFile> files, {String? text})? shareLauncher,
  }) async {
    final fileToShare = xFile ?? (filePath != null ? XFile(filePath) : null);
    if (fileToShare == null) return false;

    if (shareLauncher != null) {
      await shareLauncher([fileToShare], text: text);
    } else {
      await Share.shareXFiles([fileToShare], text: text);
    }
    return true;
  }

  @override
  void dispose() {
    if (_isInternalClient) {
      _client.close();
    }
    super.dispose();
  }
}
