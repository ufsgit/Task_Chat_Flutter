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

    test('BookingModel parses scheduleDate and reflects in toChatItem', () {
      final jsonWithSchedule = {
        'id': 99,
        'name': 'Test Client',
        'mobile': '9876543210',
        'address': 'Test Address',
        'notes': 'Test Notes',
        'status': 'SCHEDULED',
        'stateName': 'Kerala',
        'districtName': 'Kochi',
        'areaName': 'Edapally',
        'documents': [],
        'scheduleDate': '10/28/2026',
        'createdAt': '2026-10-21T10:38:24.000Z',
      };

      final booking = BookingModel.fromJson(jsonWithSchedule);
      expect(booking.scheduleDate, '10/28/2026');

      final chatItem = booking.toChatItem();
      expect(chatItem['date'], '10/28/2026');
      expect(chatItem['scheduleDate'], '10/28/2026');
    });

    test('TodayViewModel updateStatus updates status and date in memory', () {
      todayChatItems.clear();
      todayChatItems.add({
        'title': 'Test Customer',
        'tagText': 'New',
        'date': '10/21/2026',
      });

      final vm = TodayViewModel();
      vm.updateStatus('Test Customer', 'Scheduled', newDate: '10/29/2026');

      expect(todayChatItems.first['tagText'], 'Scheduled');
      expect(todayChatItems.first['date'], '10/29/2026');
      expect(todayChatItems.first['scheduleDate'], '10/29/2026');
    });

    test('TodayViewModel buildQueryParameters includes provided fields and omits null/all fields', () {
      final vm = TodayViewModel();

      // Test default: all empty/null/All => empty map
      expect(vm.buildQueryParameters(), isEmpty);

      // Full query parameters as specified in requirement
      final params = vm.buildQueryParameters(
        search: 'Rahul',
        districtId: '1',
        dateFrom: '2026-10-01',
        dateTo: '2026-10-24',
        filterRole: '5',
        status: 'Scheduled',
        page: '1',
        limit: '15',
      );

      expect(params, {
        'search': 'Rahul',
        'districtId': '1',
        'dateFrom': '2026-10-01',
        'dateTo': '2026-10-24',
        'filterRole': '5',
        'status': 'Scheduled',
        'page': '1',
        'limit': '15',
      });

      // Partial query parameters: omits null, empty, or 'all'
      final partial = vm.buildQueryParameters(
        search: '',
        districtId: '2',
        dateFrom: null,
        dateTo: null,
        filterRole: '3',
        status: 'All',
        page: null,
        limit: null,
      );

      expect(partial, {
        'districtId': '2',
        'filterRole': '3',
      });
      expect(partial.containsKey('search'), isFalse);
      expect(partial.containsKey('dateFrom'), isFalse);
      expect(partial.containsKey('dateTo'), isFalse);
      expect(partial.containsKey('status'), isFalse);
      expect(partial.containsKey('page'), isFalse);
      expect(partial.containsKey('limit'), isFalse);
    });

    test('TodayViewModel fetchBookings sends query parameters to ApiConfig.bookings', () async {
      Uri? capturedUri;
      final mockClient = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(mockApiResponse, 200,
            headers: {'content-type': 'application/json'});
      });

      final vm = TodayViewModel(client: mockClient);
      vm.applyFilters(
        status: 'Scheduled',
        districtId: '1',
        dateFrom: '2026-10-01',
        dateTo: '2026-10-24',
        filterRole: '5',
        page: '1',
        limit: '15',
      );

      // Search query
      vm.setSearchQuery('Rahul', immediate: true);
      await vm.fetchBookings(force: true);

      expect(capturedUri, isNotNull);
      expect(capturedUri!.path, '/api/bookings');
      expect(capturedUri!.queryParameters['search'], 'Rahul');
      expect(capturedUri!.queryParameters['districtId'], '1');
      expect(capturedUri!.queryParameters['dateFrom'], '2026-10-01');
      expect(capturedUri!.queryParameters['dateTo'], '2026-10-24');
      expect(capturedUri!.queryParameters['filterRole'], '5');
      expect(capturedUri!.queryParameters['status'], 'Scheduled');
      expect(capturedUri!.queryParameters['page'], '1');
      expect(capturedUri!.queryParameters['limit'], '15');

      // Reset filters and verify null/empty keys are omitted
      vm.resetFilters();
      await vm.fetchBookings(force: true);
      expect(capturedUri!.queryParameters, isEmpty);
    });
  });
}

