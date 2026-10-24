import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/api/api.dart';
import 'package:task_chat/api/document_upload_service.dart';
import 'package:task_chat/login_page/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TokenStorage.useMemoryOnly = true;
  });

  tearDown(() {
    TokenStorage.useMemoryOnly = false;
  });

  group('DocumentUploadService Unit Tests', () {
    test('uploadFile successfully uploads bytes and returns server URL', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), ApiConfig.uploads);
        expect(request.method, 'POST');
        expect(request.headers['authorization'], contains('test_token'));

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'File uploaded successfully.',
            'url': '/uploads/1792817691073-test.pdf',
            'filename': '1792817691073-test.pdf',
            'originalname': 'test.pdf',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final tokenStorage = TokenStorage();
      await tokenStorage.savetoken('test_token');

      final service = DocumentUploadService(
        client: mockClient,
        tokenStorage: tokenStorage,
      );

      final result = await service.uploadFile(
        fileName: 'test.pdf',
        bytes: utf8.encode('PDF Content'),
      );

      expect(result, '/uploads/1792817691073-test.pdf');
    });

    test('uploadFile returns null on server failure status code', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Server error'}),
          500,
        );
      });

      final tokenStorage = TokenStorage();
      final service = DocumentUploadService(
        client: mockClient,
        tokenStorage: tokenStorage,
      );

      final result = await service.uploadFile(
        fileName: 'test.pdf',
        bytes: utf8.encode('PDF Content'),
      );

      expect(result, isNull);
    });

    test('uploadFile returns null when bytes and path are missing', () async {
      final tokenStorage = TokenStorage();
      final service = DocumentUploadService(tokenStorage: tokenStorage);

      final result = await service.uploadFile(
        fileName: 'test.pdf',
      );

      expect(result, isNull);
    });
  });
}
