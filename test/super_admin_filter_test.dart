import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_chat/bottom_navigator/bottom_navigator.dart';
import 'package:task_chat/login_page/token_storage.dart';
import 'package:task_chat/Coordinator/cordinator_page.dart';
import 'package:task_chat/Coordinator/widgets/super_admin_filter_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TokenStorage.useMemoryOnly = true;
    TokenStorage().savetoken('test_mock_token');
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
    TokenStorage.useMemoryOnly = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  testWidgets(
      'SuperAdminPage renders search bar and filter button with Status and Branch Manager options',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SuperAdminPage(),
      ),
    );

    // Verify search bar and filter icon exist
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

    // Tap filter button to open bottom sheet
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    // Verify both Status and Branch Manager filter sections are displayed
    expect(find.text('Filter Options'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Branch Manager'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(SuperAdminFilterBottomSheet),
        matching: find.text('Sarah Jenkins'),
      ),
      findsOneWidget,
    );
    expect(find.text('Apply Filters'), findsOneWidget);

    // Select 'Completed' status inside bottom sheet
    await tester.tap(
      find.descendant(
        of: find.byType(SuperAdminFilterBottomSheet),
        matching: find.text('Completed'),
      ),
    );
    await tester.pumpAndSettle();

    // Select 'Sarah Jenkins' branch manager
    await tester.tap(
      find.descendant(
        of: find.byType(SuperAdminFilterBottomSheet),
        matching: find.text('Sarah Jenkins'),
      ),
    );
    await tester.pumpAndSettle();

    // Apply filters
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    // Verify modal dismissed and active filter badges appear
    expect(find.text('Filter Options'), findsNothing);
    expect(find.text('Status: Completed'), findsOneWidget);
    expect(find.text('Manager: Sarah Jenkins'), findsOneWidget);
  });

  test('CoordinatorViewModel manages filters, search, and state properly in MVVM', () {
    final vm = CoordinatorViewModel();
    expect(vm.selectedFilterIndex, 0);
    expect(vm.selectedStatusFilter, 'All');
    expect(vm.selectedManagerFilter, 'All');
    expect(vm.hasActiveFilters, isFalse);

    // Filter index
    vm.setFilterIndex(1);
    expect(vm.selectedFilterIndex, 1);

    // Apply status and manager filter
    vm.applyFilters('Completed', 'Sarah Jenkins');
    expect(vm.selectedStatusFilter, 'Completed');
    expect(vm.selectedManagerFilter, 'Sarah Jenkins');
    expect(vm.hasActiveFilters, isTrue);

    // Reset filters
    vm.resetFilters();
    expect(vm.selectedStatusFilter, 'All');
    expect(vm.selectedManagerFilter, 'All');
    expect(vm.hasActiveFilters, isFalse);

    // Search query
    vm.searchController.text = 'non_existent_query_xyz';
    expect(vm.filteredChatItems, isEmpty);

    vm.clearSearch();
    expect(vm.searchController.text, isEmpty);

    vm.dispose();
  });

  test('CoordinatorViewModel fetchBookings loads from API and maps branch manager', () async {
    final mockClient = MockClient((request) async {
      if (request.url.path.endsWith('/api/bookings')) {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': [
              {
                'id': 101,
                'name': 'Customer One',
                'mobile': '9876543210',
                'address': 'MG Road',
                'notes': 'Urgent requirement',
                'status': 'NEW',
                'loginName': 'Sarah Jenkins',
                'areaName': 'Edapally',
                'districtName': 'Ernakulam',
                'documents': [],
              },
            ],
          }),
          200,
        );
      }
      return http.Response('Not Found', 404);
    });

    final vm = CoordinatorViewModel(client: mockClient);
    await vm.fetchBookings();

    expect(vm.isLoading, false);
    expect(vm.errorMessage, isNull);
    expect(vm.bookings.length, 1);
    expect(vm.filteredChatItems.length, 1);
    expect(vm.filteredChatItems.first['title'], 'Customer One');
    expect(vm.filteredChatItems.first['branchManager'], 'Sarah Jenkins');
    expect(vm.filteredChatItems.first['role'], 'Branch Manager');
  });

  testWidgets('BottomNavigator calls fetchBookings on CoordinatorViewModel for coordinator', (tester) async {
    var fetchCalled = 0;
    final mockClient = MockClient((request) async {
      fetchCalled++;
      return http.Response(
        jsonEncode({
          'status': 'success',
          'data': [],
        }),
        200,
      );
    });

    final vm = CoordinatorViewModel(client: mockClient);

    await tester.pumpWidget(
      MaterialApp(
        home: BottomNavigator(
          isCoordinator: true,
          coordinatorViewModel: vm,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fetchCalled, greaterThanOrEqualTo(1));
  });

  test('CoordinatorViewModel ignores concurrent fetchBookings calls when already loading', () async {
    int requestCount = 0;
    final mockClient = MockClient((request) async {
      requestCount++;
      await Future.delayed(const Duration(milliseconds: 50));
      return http.Response(
        jsonEncode({'status': 'success', 'data': []}),
        200,
      );
    });

    final vm = CoordinatorViewModel(client: mockClient);
    final future1 = vm.fetchBookings();
    final future2 = vm.fetchBookings();
    await Future.wait([future1, future2]);

    expect(requestCount, 1);
  });
}

