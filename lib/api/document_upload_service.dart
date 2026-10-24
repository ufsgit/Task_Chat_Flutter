import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../login_page/token_storage.dart';
import 'api.dart';
import 'authenticated_client.dart';

/// Service for uploading files to the backend server.
class DocumentUploadService {
  final http.Client client;
  final TokenStorage? tokenStorage;

  DocumentUploadService({
    http.Client? client,
    this.tokenStorage,
  }) : client = client ?? AuthenticatedClient();

  /// Uploads a file to POST /api/uploads.
  /// Accepts [bytes] or [filePath].
  /// Returns the uploaded file URL (e.g. '/uploads/1792817691073-doc.pdf') on success,
  /// or null on failure.
  Future<String?> uploadFile({
    required String fileName,
    List<int>? bytes,
    String? filePath,
  }) async {
    try {
      List<int>? fileBytes = bytes;
      if ((fileBytes == null || fileBytes.isEmpty) && filePath != null && !kIsWeb) {
        final file = File(filePath);
        if (await file.exists()) {
          fileBytes = await file.readAsBytes();
        }
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        debugPrint('Upload aborted: No file bytes available for $fileName');
        return null;
      }

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

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          fileBytes,
          filename: fileName,
        ),
      );

      final streamedResponse =
          await client.send(request).timeout(const Duration(seconds: 30));

      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['url'] != null) {
          return decoded['url'] as String;
        }
      } else {
        debugPrint('Upload failed with status code ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('Document upload exception: $e');
    }
    return null;
  }
}
