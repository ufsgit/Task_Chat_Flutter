import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../login_page/token_storage.dart';
import 'api.dart';
import 'authenticated_client.dart';

/// Data class representing a file to be uploaded.
class UploadFileData {
  final String fileName;
  final List<int>? bytes;
  final String? filePath;

  const UploadFileData({
    required this.fileName,
    this.bytes,
    this.filePath,
  });
}

/// Service for uploading files (single or multiple) to POST /api/uploads/multiple.
class DocumentUploadService {
  final http.Client client;
  final TokenStorage? tokenStorage;

  DocumentUploadService({
    http.Client? client,
    this.tokenStorage,
  }) : client = client ?? AuthenticatedClient();

  /// Uploads up to 10 files in a single multipart request to POST /api/uploads/multiple.
  /// If [bookingId] is provided, the backend will automatically append the uploaded files
  /// to that booking's documents column in the database in the same call.
  /// Returns a list of uploaded file URLs (e.g. ['/uploads/123-file.pdf']).
  Future<List<String>> uploadMultipleFiles({
    required List<UploadFileData> files,
    dynamic bookingId,
    String fieldName = 'files',
  }) async {
    if (files.isEmpty) {
      debugPrint('Upload aborted: No files provided.');
      return [];
    }

    // Limit to 10 files as per API specification
    final targetFiles = files.length > 10 ? files.sublist(0, 10) : files;

    try {
      final uri = Uri.parse(ApiConfig.uploads);
      final request = http.MultipartRequest('POST', uri);

      String? token;
      try {
        token = await (tokenStorage ?? TokenStorage()).getToken();
      } catch (_) {}

      if (token != null && token.isNotEmpty) {
        request.headers['authorization'] =
            token.startsWith('Bearer ') ? token : 'Bearer $token';
      }

      // Add bookingId if provided
      if (bookingId != null && bookingId.toString().trim().isNotEmpty) {
        request.fields['bookingId'] = bookingId.toString().trim();
      }

      // Process and attach files
      int attachedCount = 0;
      for (final file in targetFiles) {
        List<int>? fileBytes = file.bytes;
        if ((fileBytes == null || fileBytes.isEmpty) &&
            file.filePath != null &&
            !kIsWeb) {
          final ioFile = File(file.filePath!);
          if (await ioFile.exists()) {
            fileBytes = await ioFile.readAsBytes();
          }
        }

        if (fileBytes != null && fileBytes.isNotEmpty) {
          request.files.add(
            http.MultipartFile.fromBytes(
              fieldName,
              fileBytes,
              filename: file.fileName,
            ),
          );
          attachedCount++;
        } else {
          debugPrint('Skipping ${file.fileName}: No bytes available.');
        }
      }

      if (attachedCount == 0) {
        debugPrint('Upload aborted: No valid file bytes found in file list.');
        return [];
      }

      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 45));

      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final urls = _extractUrls(decoded);
        return urls;
      } else {
        debugPrint(
            'Upload failed with status code ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Document upload exception: $e');
    }
    return [];
  }

  /// Uploads a single file to POST /api/uploads/multiple.
  /// Accepts [bytes] or [filePath].
  /// If [bookingId] is provided, the backend automatically appends the document to the booking.
  /// Returns the uploaded file URL (e.g. '/uploads/1792817691073-doc.pdf') on success,
  /// or null on failure.
  Future<String?> uploadFile({
    required String fileName,
    List<int>? bytes,
    String? filePath,
    dynamic bookingId,
    String fieldName = 'files',
  }) async {
    final urls = await uploadMultipleFiles(
      files: [
        UploadFileData(
          fileName: fileName,
          bytes: bytes,
          filePath: filePath,
        ),
      ],
      bookingId: bookingId,
      fieldName: fieldName,
    );
    return urls.isNotEmpty ? urls.first : null;
  }

  /// Robustly extracts document URLs from various backend response payload formats.
  static List<String> _extractUrls(dynamic decoded) {
    final List<String> urls = [];

    void extractFromList(List<dynamic> list) {
      for (final item in list) {
        if (item is String && item.isNotEmpty) {
          urls.add(item);
        } else if (item is Map) {
          final u = item['url'] ?? item['path'] ?? item['filename'];
          if (u != null && u.toString().isNotEmpty) {
            final urlStr = u.toString();
            urls.add(urlStr.startsWith('/') || urlStr.startsWith('http')
                ? urlStr
                : '/uploads/$urlStr');
          }
        }
      }
    }

    if (decoded is List) {
      extractFromList(decoded);
    } else if (decoded is Map<String, dynamic>) {
      if (decoded['urls'] is List) {
        extractFromList(decoded['urls'] as List);
      } else if (decoded['files'] is List) {
        extractFromList(decoded['files'] as List);
      } else if (decoded['documents'] is List) {
        extractFromList(decoded['documents'] as List);
      } else if (decoded['data'] is List) {
        extractFromList(decoded['data'] as List);
      } else if (decoded['data'] is Map) {
        final dataMap = decoded['data'] as Map;
        if (dataMap['urls'] is List) extractFromList(dataMap['urls'] as List);
        if (dataMap['files'] is List) extractFromList(dataMap['files'] as List);
        if (dataMap['documents'] is List) {
          extractFromList(dataMap['documents'] as List);
        }
        if (dataMap['url'] != null) urls.add(dataMap['url'].toString());
      } else if (decoded['booking'] is Map &&
          (decoded['booking'] as Map)['documents'] is List) {
        extractFromList((decoded['booking'] as Map)['documents'] as List);
      }

      if (urls.isEmpty && decoded['url'] != null) {
        urls.add(decoded['url'].toString());
      }
    }

    return urls;
  }
}
