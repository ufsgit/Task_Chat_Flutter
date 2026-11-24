import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../api/api.dart';
import '../api/authenticated_client.dart';
import '../login_page/token_storage.dart';
import '../today/today_model.dart';
import '../update_status/status_update_result.dart';
import 'customer_details_model.dart';
import 'widgets/customer_header_card.dart';

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
  })  : _client = client ?? AuthenticatedClient(),
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
      final headers = await (tokenStorage ?? TokenStorage()).authHeaders(includeContentType: true);
      final uri = Uri.parse('${ApiConfig.bookings}/${customer.id}');

      final updatedName = name ?? customer.name;
      final updatedPhone = phoneNumber ?? customer.phoneNumber;
      final updatedAddress = address ??
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
    final wasScheduled = newStatus.toLowerCase() == 'scheduled' ||
        customer.hasBeenScheduled;
    customer = customer.copyWith(
      status: newStatus,
      scheduleDate: scheduleDate ?? customer.scheduleDate,
      hasBeenScheduled: wasScheduled,
    );
    notifyListeners();
  }

  /// Applies a full status update result from Update Status page.
  void applyUpdate(StatusUpdateResult result) {
    final wasScheduled = result.status.toLowerCase() == 'scheduled' ||
        customer.hasBeenScheduled;
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
    if (customer.scheduleDate != null && customer.scheduleDate!.trim().isNotEmpty) {
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
    if (customer.branchHeadName != null && customer.branchHeadName!.trim().isNotEmpty) {
      buffer.writeln('*Branch Manager:* ${customer.branchHeadName!.trim()}');
    }
    return buffer.toString().trim();
  }

  /// Shares all customer information as text directly to the customer's WhatsApp number.
  Future<bool> shareDataToWhatsApp({
    Future<void> Function(String phone, {String? text})? whatsAppLauncher,
  }) async {
    final phone = customer.phoneNumber.trim();
    if (phone.isEmpty) return false;
    final text = formatCustomerDataForSharing();
    final launcher = whatsAppLauncher ?? openWhatsApp;
    await launcher(phone, text: text);
    return true;
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

    final shareText = text ?? 'Hello ${customer.name}, please find our brochure attached.';
    if (shareLauncher != null) {
      await shareLauncher([fileToShare], text: shareText);
    } else {
      await Share.shareXFiles([fileToShare], text: shareText);
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
