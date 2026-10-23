import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/bottom_navigator/bottom_navigator.dart';
import 'package:task_chat/Coordinator/coordinator_view_model.dart';
import 'package:task_chat/today/today_model.dart';
import 'package:task_chat/today/today_view_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return 'test_mock_token';
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  group('TodayViewModel & BookingModel MVVM Tests', () {
    const mockApiResponse = '''
    {
      "data": [
        {
          "id": 2,
          "name": "Rahul Krishnan",
          "mobile": "+91 94471 22334",
          "address": "House 12, MG Road, Ernakulam",
          "notes": "Double door fitting required",
          "status": "NEW",
          "loginRoleId": 2,
          "loginId": 2,
          "loginName": "Elena Vance",
          "stateId": 1,
          "stateName": "Kerala",
          "districtId": 1,
          "districtName": "Ernakulam Hub",
          "areaId": 1,
          "areaName": "Edapally",
          "documents": ["/uploads/site_plan.pdf"],
          "createdAt": "2026-10-21T10:38:24.000Z",
          "updatedAt": "2026-10-21T10:38:24.000Z"
        },
        {
          "id": 1,
          "name": "Anand Varma",
          "mobile": "+91 98470 11223",
          "address": "Flat 4B, SkyLine Apts, Palarivattom",
          "notes": "Urgent fitting required",
          "status": "COMPLETED",
          "loginRoleId": 2,
          "loginId": 2,
          "loginName": "Elena Vance",
          "stateId": 1,
          "stateName": "Kerala",
          "districtId": 1,
          "districtName": "Ernakulam Hub",
          "areaId": 4,
          "areaName": "Palarivattom",
          "documents": [],
          "createdAt": "2026-10-21T07:14:20.000Z",
          "updatedAt": "2026-10-21T07:14:20.000Z"
        }
      ]
    }
    ''';

    test('BookingModel parses API json response correctly', () {
      final jsonMap = (jsonDecode(mockApiResponse)['data'] as List).first;
      final model = BookingModel.fromJson(jsonMap);

      expect(model.id, 2);
      expect(model.name, 'Rahul Krishnan');
      expect(model.mobile, '+91 94471 22334');
      expect(model.address, 'House 12, MG Road, Ernakulam');
      expect(model.areaName, 'Edapally');
      expect(model.status, 'NEW');
      expect(model.documents.length, 1);

      final chatItem = model.toChatItem();
      expect(chatItem['title'], 'Rahul Krishnan');
      expect(chatItem['avatarLetter'], 'R');
      expect(chatItem['tagText'], 'New');
      expect(chatItem['location'], 'Edapally');
      expect(chatItem['hasVerifiedBadge'], false);
    });

    test('TodayViewModel fetches bookings and filters correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(mockApiResponse, 200,
            headers: {'content-type': 'application/json'});
      });

      final vm = TodayViewModel(client: mockClient);
      await vm.fetchBookings();

      expect(vm.bookings.length, 2);
      expect(vm.filteredChatItems.length, 2);

      // Search filter
      vm.setSearchQuery('Rahul');
      expect(vm.filteredChatItems.length, 1);
      expect(vm.filteredChatItems.first['title'], 'Rahul Krishnan');

      // Clear search
      vm.setSearchQuery('');
      expect(vm.filteredChatItems.length, 2);

      // Status filter
      vm.setStatusFilter('Completed');
      expect(vm.filteredChatItems.length, 1);
      expect(vm.filteredChatItems.first['title'], 'Anand Varma');
    });

    test('TodayViewModel sends authorization header when token is stored',
        () async {
      String? authHeader;
      final mockClient = MockClient((request) async {
        authHeader = request.headers['authorization'];
        return http.Response(mockApiResponse, 200,
            headers: {'content-type': 'application/json'});
      });

      final vm = TodayViewModel(client: mockClient);
      await vm.fetchBookings();

      expect(authHeader, 'Bearer test_mock_token');
    });

    testWidgets(
        'BottomNavigator calls fetchBookings whenever Today page is selected',
        (WidgetTester tester) async {
      int fetchCount = 0;
      final mockClient = MockClient((request) async {
        fetchCount++;
        return http.Response(mockApiResponse, 200,
            headers: {'content-type': 'application/json'});
      });

      final vm = TodayViewModel(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: BottomNavigator(todayViewModel: vm),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Initial load calls fetchBookings once
      expect(fetchCount, 1);

      // Tap Dashboard tab (index 1)
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(fetchCount, 1);

      // Tap Today tab (index 0) - selects Today page again
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // fetchBookings must be called again
      expect(fetchCount, 2);

      // Tap Today tab a second time while on Today page
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // fetchBookings must be called every time it is selected
      expect(fetchCount, 3);
    });

    test('TodayViewModel ignores concurrent fetchBookings calls when already loading', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        return http.Response(mockApiResponse, 200,
            headers: {'content-type': 'application/json'});
      });

      final vm = TodayViewModel(client: mockClient);
      final future1 = vm.fetchBookings();
      final future2 = vm.fetchBookings();
      await Future.wait([future1, future2]);

      expect(requestCount, 1);
    });

    testWidgets('BottomNavigator configures extendBody true on Scaffold', (tester) async {
      final mock = MockClient((_) async => http.Response('{"data":[]}', 200));
      final vm = TodayViewModel(client: mock);
      final cvm = CoordinatorViewModel(client: mock);
      await tester.pumpWidget(
        MaterialApp(
          home: BottomNavigator(todayViewModel: vm, coordinatorViewModel: cvm),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.extendBody, true);
    });
  });
}

