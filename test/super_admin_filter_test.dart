import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_chat/bottom_navigator/bottom_navigator.dart';
import 'package:task_chat/login_page/token_storage.dart';
import 'package:task_chat/Coordinator/coordinator_view.dart';
import 'package:task_chat/Coordinator/coordinator_view_model.dart';
import 'package:task_chat/Coordinator/widgets/super_admin_filter_bottom_sheet.dart';
import 'package:task_chat/today/widgets/today_skeleton_loading.dart';

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
      'CoordinatorPage renders search bar and filter button with Status and Branch Manager options',
      (WidgetTester tester) async {
    final vm = CoordinatorViewModel(
      initialItems: [
        {
          'id': '1',
          'title': 'Test Customer',
          'location': 'Bangalore',
          'tagText': 'New',
          'date': '01/01/2026',
          'branchManager': 'Sarah Jenkins',
          'isPending': true,
        }
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CoordinatorPage(viewModel: vm),
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
    expect(find.byKey(const Key('branch_manager_dropdown')), findsOneWidget);
    expect(find.text('Apply Filters'), findsOneWidget);

    // Select 'Completed' status inside bottom sheet
    await tester.tap(
      find.descendant(
        of: find.byType(CoordinatorFilterBottomSheet),
        matching: find.text('Completed'),
      ),
    );
    await tester.pumpAndSettle();

    // Tap dropdown to reveal branch manager options
    await tester.tap(find.byKey(const Key('branch_manager_dropdown')));
    await tester.pumpAndSettle();

    // Verify Sarah Jenkins is in the dropdown menu
    expect(find.text('Sarah Jenkins'), findsWidgets);

    // Select 'Sarah Jenkins' branch manager from dropdown
    await tester.tap(find.text('Sarah Jenkins').last);
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

  test('CoordinatorViewModel scroll pagination loadNextPage fetches and appends items', () async {
    final page1Data = List.generate(
      15,
      (i) => {
        'id': i + 1,
        'name': 'Client ${i + 1}',
        'mobile': '987654321$i',
        'address': 'Kochi',
        'status': 'NEW',
        'branchHeadName': 'Manager A',
      },
    );

    final page2Data = List.generate(
      5,
      (i) => {
        'id': i + 16,
        'name': 'Client ${i + 16}',
        'mobile': '987654322$i',
        'address': 'Calicut',
        'status': 'SCHEDULED',
        'branchHeadName': 'Manager B',
      },
    );

    final mockClient = MockClient((request) async {
      final page = request.url.queryParameters['page'] ?? '1';
      if (page == '1') {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': page1Data,
            'pagination': {'currentPage': 1, 'totalPages': 2},
          }),
          200,
        );
      } else {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': page2Data,
            'pagination': {'currentPage': 2, 'totalPages': 2},
          }),
          200,
        );
      }
    });

    final vm = CoordinatorViewModel(client: mockClient);
    await vm.fetchBookings();

    expect(vm.currentPage, 1);
    expect(vm.hasMore, isTrue);
    expect(vm.filteredChatItems.length, 15);

    await vm.loadNextPage();

    expect(vm.currentPage, 2);
    expect(vm.hasMore, isFalse);
    expect(vm.filteredChatItems.length, 20);
    expect(vm.filteredChatItems.last['title'], 'Client 20');
  });

  testWidgets(
      'CoordinatorPage pop up arrow button appears when scrolled down and scrolls to top fast on tap',
      (WidgetTester tester) async {
    final manyItems = List.generate(
      30,
      (i) => {
        'id': '$i',
        'title': 'Coordinator Lead $i',
        'location': 'Location $i',
        'tagText': 'New',
        'date': '04/11/2026',
        'branchManager': 'Manager $i',
        'isPending': true,
      },
    );

    final vm = CoordinatorViewModel(initialItems: manyItems);

    await tester.pumpWidget(
      MaterialApp(
        home: CoordinatorPage(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();

    final scrollToTopButtonFinder = find.byKey(const Key('coordinator_scroll_to_top_button'));
    expect(scrollToTopButtonFinder, findsOneWidget);

    // At top (offset 0), AnimatedScale should have scale 0.0
    final AnimatedScale initialScale = tester.widget(scrollToTopButtonFinder);
    expect(initialScale.scale, 0.0);

    // Scroll down by 600 pixels
    final listViewFinder = find.byType(ListView);
    await tester.drag(listViewFinder, const Offset(0, -600));
    await tester.pumpAndSettle();

    // Now button should pop up (scale 1.0)
    final AnimatedScale poppedScale = tester.widget(scrollToTopButtonFinder);
    expect(poppedScale.scale, 1.0);

    // Tap the scroll to top button
    await tester.tap(scrollToTopButtonFinder);
    await tester.pumpAndSettle();

    // Verify it reached top
    final ScrollableState scrollable = tester.state(find.byType(Scrollable).first);
    expect(scrollable.position.pixels, 0.0);

    // Verify button scaled back down to 0.0
    final AnimatedScale endScale = tester.widget(scrollToTopButtonFinder);
    expect(endScale.scale, 0.0);
  });

  test('CoordinatorViewModel excludes Rajesh Menon from branchManagerOptions', () {
    final vm = CoordinatorViewModel(
      initialItems: [
        {'id': '1', 'branchManager': 'Rajesh Menon'},
        {'id': '2', 'branchManager': 'rajesh menon'},
        {'id': '3', 'branchManager': 'Sarah Jenkins'},
        {'id': '4', 'branchManager': 'Bob Smith'},
      ],
    );

    expect(vm.branchManagerOptions, isNot(contains('Rajesh Menon')));
    expect(vm.branchManagerOptions, isNot(contains('rajesh menon')));
    expect(vm.branchManagerOptions, containsAll(['All', 'Sarah Jenkins', 'Bob Smith']));
  });

  testWidgets(
      'CoordinatorFilterBottomSheet excludes Rajesh Menon and renders dropdown with Apply button visible',
      (WidgetTester tester) async {
    String appliedStatus = '';
    String appliedManager = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CoordinatorFilterBottomSheet(
            selectedStatus: 'All',
            selectedBranchManager: 'All',
            statusOptions: const ['All', 'New', 'Completed'],
            branchManagerOptions: const ['All', 'Rajesh Menon', 'John Doe'],
            onApply: (status, manager) {
              appliedStatus = status;
              appliedManager = manager;
            },
            onReset: () {},
          ),
        ),
      ),
    );

    // Verify Dropdown is rendered
    expect(find.byKey(const Key('branch_manager_dropdown')), findsOneWidget);
    expect(find.text('Apply Filters'), findsOneWidget);

    // Open dropdown
    await tester.tap(find.byKey(const Key('branch_manager_dropdown')));
    await tester.pumpAndSettle();

    // Verify 'Rajesh Menon' is NOT present in options, but 'John Doe' is
    expect(find.text('Rajesh Menon'), findsNothing);
    expect(find.text('John Doe'), findsWidgets);

    // Select John Doe
    await tester.tap(find.text('John Doe').last);
    await tester.pumpAndSettle();

    // Tap Apply Filters
    await tester.tap(find.text('Apply Filters'));
    await tester.pumpAndSettle();

    expect(appliedStatus, 'All');
    expect(appliedManager, 'John Doe');
  });

  test('CoordinatorViewModel status filter passes status and statusId in API pagination', () async {
    final requestedUris = <Uri>[];
    final mockClient = MockClient((request) async {
      requestedUris.add(request.url);
      final page = request.url.queryParameters['page'] ?? '1';
      final status = request.url.queryParameters['status'];

      if (page == '1') {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': [
              {
                'id': 101,
                'name': 'Client 101',
                'mobile': '9876543210',
                'address': 'Kochi',
                'status': status ?? 'Completed',
                'branchHeadName': 'Manager A',
              },
            ],
            'pagination': {'currentPage': 1, 'totalPages': 2},
          }),
          200,
        );
      } else {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'data': [
              {
                'id': 102,
                'name': 'Client 102',
                'mobile': '9876543220',
                'address': 'Calicut',
                'status': status ?? 'Completed',
                'branchHeadName': 'Manager B',
              },
            ],
            'pagination': {'currentPage': 2, 'totalPages': 2},
          }),
          200,
        );
      }
    });

    final vm = CoordinatorViewModel(client: mockClient);
    vm.setStatusFilter('Completed');
    await pumpEventQueue();

    expect(requestedUris, isNotEmpty);
    final page1Uri = requestedUris.first;
    expect(page1Uri.queryParameters['page'], '1');
    expect(page1Uri.queryParameters['status'], 'Completed');
    expect(page1Uri.queryParameters['statusId'], '3');
    expect(vm.filteredChatItems.length, 1);
    expect(vm.hasMore, isTrue);

    await vm.loadNextPage();
    expect(requestedUris.length, 2);
    final page2Uri = requestedUris[1];
    expect(page2Uri.queryParameters['page'], '2');
    expect(page2Uri.queryParameters['status'], 'Completed');
    expect(page2Uri.queryParameters['statusId'], '3');
    expect(vm.filteredChatItems.length, 2);
    expect(vm.hasMore, isFalse);

    vm.dispose();
  });

  test('CoordinatorViewModel passes districtId, district_id, branchHeadId and branchManager when filtering by Branch Head', () async {
    final requestedUris = <Uri>[];
    final mockClient = MockClient((request) async {
      requestedUris.add(request.url);
      if (request.url.path.contains('get_branch_heads_for_status_update')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 5,
                'name': 'Branch Head - Kottayam',
                'district_id': 5,
                'district_name': 'Kottayam'
              },
              {
                'id': 7,
                'name': 'Branch Head - Ernakulam',
                'district_id': 7,
                'district_name': 'Ernakulam'
              }
            ]
          }),
          200,
        );
      }
      return http.Response(
        jsonEncode({
          'status': 'success',
          'data': [
            {
              'id': 101,
              'name': 'Client 101',
              'mobile': '9876543210',
              'address': 'Kottayam',
              'status': 'New',
              'districtId': 5,
              'districtName': 'Kottayam',
              'branchHeadId': 5,
              'branchHeadName': 'Branch Head - Kottayam',
            },
          ],
          'pagination': {'currentPage': 1, 'totalPages': 1, 'total': 1},
        }),
        200,
      );
    });

    final vm = CoordinatorViewModel(client: mockClient);
    vm.setManagerFilter('Branch Head - Kottayam');
    await pumpEventQueue();

    expect(requestedUris, isNotEmpty);
    final bookingUri = requestedUris.firstWhere((u) => u.path.contains('/api/bookings'));
    expect(bookingUri.queryParameters['branchManager'], 'Branch Head - Kottayam');
    expect(bookingUri.queryParameters['districtId'], '5');
    expect(bookingUri.queryParameters['district_id'], '5');
    expect(bookingUri.queryParameters['branchHeadId'], '5');
    expect(vm.filteredChatItems.length, 1);
    expect(vm.filteredChatItems.first['branchManager'], 'Branch Head - Kottayam');

    vm.dispose();
  });

  testWidgets(
      'CoordinatorPage does not automatically trigger runaway loadNextPage when filtered count is small',
      (WidgetTester tester) async {
    int loadNextPageCalls = 0;
    final mockClient = MockClient((request) async {
      final page = request.url.queryParameters['page'] ?? '1';
      if (page != '1') {
        loadNextPageCalls++;
      }
      return http.Response(
        jsonEncode({
          'status': 'success',
          'data': [
            {
              'id': 1,
              'name': 'Single Lead',
              'mobile': '9876543210',
              'address': 'Kottayam',
              'status': 'New',
              'districtId': 5,
              'branchHeadId': 5,
              'branchHeadName': 'Branch Head - Kottayam',
            }
          ],
          'pagination': {'currentPage': int.parse(page), 'totalPages': 5, 'total': 5},
        }),
        200,
      );
    });

    final vm = CoordinatorViewModel(client: mockClient);
    await vm.fetchBookings();
    expect(vm.filteredChatItems.length, 1);
    expect(vm.hasMore, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: CoordinatorPage(viewModel: vm),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Because filtered.length < 10 and user has not scrolled, loadNextPage should NOT have been called
    expect(loadNextPageCalls, 0);

    vm.dispose();
  });

  testWidgets(
      'CoordinatorPage clears old chats and renders skeleton loader while fetching new filter',
      (WidgetTester tester) async {
    final completer = Completer<http.Response>();
    final mockClient = MockClient((request) async {
      return completer.future;
    });

    final vm = CoordinatorViewModel(
      client: mockClient,
      initialItems: [
        {
          'id': '10',
          'title': 'Old Client 1',
          'location': 'Kottayam',
          'tagText': 'New',
          'date': '01/01/2026',
          'branchManager': 'Branch Head - Kottayam',
          'isPending': true,
        },
        {
          'id': '20',
          'title': 'Old Client 2',
          'location': 'Ernakulam',
          'tagText': 'New',
          'date': '01/01/2026',
          'branchManager': 'Branch Head - Ernakulam',
          'isPending': true,
        },
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CoordinatorPage(viewModel: vm),
      ),
    );
    await tester.pump();

    // Initially old items are present
    expect(find.text('Old Client 1'), findsOneWidget);
    expect(find.text('Old Client 2'), findsOneWidget);

    // Apply a new filter
    vm.applyFilters('All', 'Branch Head - Kottayam');
    await tester.pump();

    // Old chats are cleared immediately and skeleton loader is displayed
    expect(find.text('Old Client 1'), findsNothing);
    expect(find.text('Old Client 2'), findsNothing);
    expect(find.byType(TodaySkeletonLoading), findsOneWidget);

    // Resolve network request with newly filtered data
    completer.complete(
      http.Response(
        jsonEncode({
          'status': 'success',
          'data': [
            {
              'id': 101,
              'name': 'Fresh Kottayam Lead',
              'mobile': '9876543210',
              'address': 'Kottayam',
              'status': 'New',
              'districtId': 5,
              'branchHeadId': 5,
              'branchHeadName': 'Branch Head - Kottayam',
            }
          ],
          'pagination': {'currentPage': 1, 'totalPages': 1, 'total': 1},
        }),
        200,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    // Skeleton loader disappears and fresh lead appears
    expect(find.byType(TodaySkeletonLoading), findsNothing);
    expect(find.text('Fresh Kottayam Lead'), findsOneWidget);

    vm.dispose();
  });
}

