import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_chat/api/api.dart';
import 'package:task_chat/core/widgets/app_pill_notification.dart';
import 'package:task_chat/core/widgets/circular_back_button.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/customer_details_view.dart';
import 'package:task_chat/services/notification_service.dart';
import 'package:task_chat/today/today_model.dart';

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

  group('NotificationService Push Routing & Deep Linking Tests', () {
    test('parseCustomerFromData parses complete booking payload correctly', () {
      final payload = {
        'booking_id': '10045',
        'customer_name': 'Devika Nair',
        'status': 'Scheduled',
        'mobile': '9876501234',
        'location': 'Ernakulam',
        'notes': 'Looking for teak finish door',
        'status_color_code': '#F59E0B',
      };

      final customer = NotificationService.parseCustomerFromData(payload);

      expect(customer, isNotNull);
      expect(customer!.id, equals('10045'));
      expect(customer.name, equals('Devika Nair'));
      expect(customer.status, equals('Scheduled'));
      expect(customer.phoneNumber, equals('9876501234'));
      expect(customer.notes, equals('Looking for teak finish door'));
      expect(customer.statusColorCode, equals('#F59E0B'));
    });

    test('parseCustomerFromData extracts booking ID from text when missing from data', () {
      final payload = <String, dynamic>{
        'message': 'New assignment for booking #10099',
      };

      final customer = NotificationService.parseCustomerFromData(payload);

      expect(customer, isNotNull);
      expect(customer!.id, equals('10099'));
      expect(customer.name, equals('Booking #10099'));
    });

    test('CustomerDetailsModel.fromBooking maps BookingModel into customer details model', () {
      final booking = BookingModel(
        id: 10077,
        name: 'Arun Kumar',
        mobile: '9847012345',
        address: 'MG Road',
        notes: 'Needs immediate installation',
        status: 'Completed',
        stateName: 'Kerala',
        districtName: 'Kozhikode',
        areaName: 'Mavoor Road',
        documents: ['https://example.com/doc1.pdf'],
        statusColorCode: '#10B981',
      );

      final customer = CustomerDetailsModel.fromBooking(booking);

      expect(customer.id, equals('10077'));
      expect(customer.name, equals('Arun Kumar'));
      expect(customer.phoneNumber, equals('9847012345'));
      expect(customer.status, equals('Completed'));
      expect(customer.documents, contains('https://example.com/doc1.pdf'));
      expect(customer.statusColorCode, equals('#10B981'));
    });

    testWidgets('navigateToBooking opens CustomerDetailsPage like WhatsApp chat navigation', (
      WidgetTester tester,
    ) async {
      final navKey = GlobalKey<NavigatorState>();
      NotificationService.navigatorKey = navKey;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Center(child: Text('Home Screen'))),
        ),
      );
      expect(find.text('Home Screen'), findsOneWidget);

      final customer = CustomerDetailsModel.fromChatInfo(
        id: '20001',
        name: 'Suresh Gopi',
        location: 'Trivandrum',
        tagText: 'Scheduled',
      );

      // Trigger navigation as if notification was clicked outside the app
      await NotificationService.navigateToBooking(customer);
      await tester.pumpAndSettle();

      // Verify we arrived on CustomerDetailsPage
      expect(find.byType(CustomerDetailsPage), findsOneWidget);
      expect(find.text('Suresh Gopi'), findsOneWidget);

      // Verify back navigation pops back to home screen
      await tester.tap(find.byType(CircularBackButton));
      await tester.pumpAndSettle();

      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.byType(CustomerDetailsPage), findsNothing);
    });

    testWidgets('checkAndNavigatePending opens queued booking once UI is ready', (
      WidgetTester tester,
    ) async {
      final navKey = GlobalKey<NavigatorState>();
      NotificationService.navigatorKey = navKey;

      final pending = CustomerDetailsModel.fromChatInfo(
        id: '30001',
        name: 'Mammootty',
        tagText: 'New',
      );

      // Set pending customer (e.g. from terminated state launch via getInitialMessage)
      NotificationService.pendingCustomer = pending;

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Center(child: Text('Root Screen'))),
        ),
      );

      // Run checkAndNavigatePending
      await NotificationService.checkAndNavigatePending();
      await tester.pumpAndSettle();

      expect(find.byType(CustomerDetailsPage), findsOneWidget);
      expect(find.text('Mammootty'), findsOneWidget);
      expect(NotificationService.pendingCustomer, isNull);
    });

    testWidgets('AppPillNotification with onTap executes callback on tap', (
      WidgetTester tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppPillNotification(
              message: 'New message received',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('New message received'), findsOneWidget);
      await tester.tap(find.byType(AppPillNotification));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}

