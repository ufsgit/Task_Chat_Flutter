import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_chat/api/api.dart';
import 'package:task_chat/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    NotificationService.fcmToken = 'mock_fcm_token_12345';
  });

  tearDown(() {
    NotificationService.fcmToken = null;
  });

  group('NotificationService Device Info Tests', () {
    test('getDeviceId generates and persists deviceId when not set', () async {
      final id1 = await NotificationService.getDeviceId();
      expect(id1, isNotEmpty);
      expect(id1.startsWith('fitmate-'), isTrue);

      final id2 = await NotificationService.getDeviceId();
      expect(id2, equals(id1));
    });

    test('getDeviceId returns stored deviceId when present in SharedPreferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fitmate_device_id', 'test-device-uuid-999');

      final id = await NotificationService.getDeviceId();
      expect(id, equals('test-device-uuid-999'));
    });

    test('getDeviceType returns non-empty device string', () {
      final deviceType = NotificationService.getDeviceType();
      expect(deviceType, isNotEmpty);
    });
  });

  group('NotificationService Backend Registration Tests', () {
    test('registerDeviceWithBackend sends POST /api/notifications/device-token with correct headers and payload', () async {
      bool called = false;
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), ApiConfig.notificationDeviceToken);
        expect(request.headers['Authorization'], 'Bearer mock_jwt_token');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['fcmToken'], 'mock_fcm_token_12345');
        expect(body['deviceToken'], 'mock_fcm_token_12345');
        expect(body['deviceType'], isNotEmpty);
        expect(body['deviceId'], isNotEmpty);

        called = true;
        return http.Response('{"success":true,"message":"Registered"}', 200);
      });

      final success = await NotificationService.registerDeviceWithBackend(
        jwtToken: 'mock_jwt_token',
        client: mockClient,
      );

      expect(success, isTrue);
      expect(called, isTrue);
    });

    test('registerDeviceWithBackend skips when token is missing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error', 500);
      });

      final success = await NotificationService.registerDeviceWithBackend(
        jwtToken: '',
        client: mockClient,
      );

      expect(success, isFalse);
    });

    test('unregisterDeviceFromBackend sends POST /api/notifications/unregister with correct headers and payload', () async {
      bool called = false;
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), ApiConfig.notificationUnregister);
        expect(request.headers['Authorization'], 'Bearer mock_jwt_token');
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['fcmToken'], 'mock_fcm_token_12345');
        expect(body.containsKey('deviceType'), isFalse);

        called = true;
        return http.Response('{"success":true,"message":"Unregistered"}', 200);
      });

      final success = await NotificationService.unregisterDeviceFromBackend(
        jwtToken: 'mock_jwt_token',
        client: mockClient,
      );

      expect(success, isTrue);
      expect(called, isTrue);
    });

    test('unregisterDeviceFromBackend skips when token is missing', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error', 500);
      });

      final success = await NotificationService.unregisterDeviceFromBackend(
        jwtToken: '',
        client: mockClient,
      );

      expect(success, isFalse);
    });
  });
}

