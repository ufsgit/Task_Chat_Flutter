import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/api/authenticated_client.dart';
import 'package:task_chat/login_page/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthenticatedClient Interceptor Tests', () {
    late TokenStorage tokenStorage;

    setUp(() {
      TokenStorage.useMemoryOnly = true;
      tokenStorage = TokenStorage();
    });

    test('401 response on protected endpoint triggers onUnauthorized and deletes token', () async {
      await tokenStorage.savetoken('test-expired-token');
      expect(await tokenStorage.getToken(), equals('test-expired-token'));

      bool unauthorizedTriggered = false;

      final mockInner = MockClient((request) async {
        return http.Response('{"error": "Unauthorized"}', 401);
      });

      final client = AuthenticatedClient(
        inner: mockInner,
        tokenStorage: tokenStorage,
        onUnauthorized: () async {
          unauthorizedTriggered = true;
        },
      );

      final response = await client.get(Uri.parse('https://example.com/api/bookings'));
      expect(response.statusCode, equals(401));

      // Wait a tick for unawaited async session purge
      await Future.delayed(const Duration(milliseconds: 50));

      expect(unauthorizedTriggered, isTrue);
      expect(await tokenStorage.getToken(), isNull);
    });

    test('401 response on /api/auth does NOT trigger onUnauthorized', () async {
      await tokenStorage.savetoken('pre-login-token');

      bool unauthorizedTriggered = false;

      final mockInner = MockClient((request) async {
        return http.Response('{"error": "Invalid credentials"}', 401);
      });

      final client = AuthenticatedClient(
        inner: mockInner,
        tokenStorage: tokenStorage,
        onUnauthorized: () async {
          unauthorizedTriggered = true;
        },
      );

      final response = await client.post(
        Uri.parse('https://example.com/api/auth/mobile-login'),
      );
      expect(response.statusCode, equals(401));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(unauthorizedTriggered, isFalse);
      expect(await tokenStorage.getToken(), equals('pre-login-token'));
    });

    test('200 OK response passes through without triggering onUnauthorized', () async {
      await tokenStorage.savetoken('valid-token');

      bool unauthorizedTriggered = false;

      final mockInner = MockClient((request) async {
        return http.Response('{"data": []}', 200);
      });

      final client = AuthenticatedClient(
        inner: mockInner,
        tokenStorage: tokenStorage,
        onUnauthorized: () async {
          unauthorizedTriggered = true;
        },
      );

      final response = await client.get(Uri.parse('https://example.com/api/bookings'));
      expect(response.statusCode, equals(200));

      await Future.delayed(const Duration(milliseconds: 50));

      expect(unauthorizedTriggered, isFalse);
      expect(await tokenStorage.getToken(), equals('valid-token'));
    });
  });
}
