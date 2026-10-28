import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/api/api.dart';
import 'package:task_chat/dashboard/dashboard_model.dart';
import 'package:task_chat/dashboard/dashboard_view.dart';
import 'package:task_chat/dashboard/dashboard_view_model.dart';
import 'package:task_chat/dashboard/widgets/custom_date_range_picker_dialog.dart';
import 'package:task_chat/dashboard/widgets/dashboard_time_filter_bar.dart';
import 'package:task_chat/dashboard/widgets/metric_stat_card.dart';
import 'package:task_chat/bottom_navigator/bottom_navigator.dart';

void main() {
  group('DashboardPeriod Mapping', () {
    test('queryValue maps correctly according to requirements', () {
      expect(DashboardPeriod.currentMonth.queryValue, 'this_month');
      expect(DashboardPeriod.last30Days.queryValue, 'last_30_days');
      expect(DashboardPeriod.allTime.queryValue, 'all');
      expect(DashboardPeriod.custom.queryValue, 'custom');
    });

    test('fromLabel parses various label strings', () {
      expect(DashboardPeriod.fromLabel('Current Month'), DashboardPeriod.currentMonth);
      expect(DashboardPeriod.fromLabel('This Month'), DashboardPeriod.currentMonth);
      expect(DashboardPeriod.fromLabel('Last 30 Days'), DashboardPeriod.last30Days);
      expect(DashboardPeriod.fromLabel('All Time'), DashboardPeriod.allTime);
      expect(DashboardPeriod.fromLabel('All'), DashboardPeriod.allTime);
      expect(DashboardPeriod.fromLabel('Custom'), DashboardPeriod.custom);
      expect(DashboardPeriod.fromLabel('custom'), DashboardPeriod.custom);
      expect(DashboardPeriod.fromLabel(null), DashboardPeriod.currentMonth);
    });
  });

  group('DashboardModel Serialization', () {
    test('parses camelCase backend response', () {
      final json = {
        'success': true,
        'data': {
          'newBooking': 42,
          'pending': 15,
          'completed': 80,
          'scheduled': 25,
          'total': 162,
        },
      };

      final model = DashboardModel.fromJson(json);
      expect(model.newBooking, 42);
      expect(model.pending, 15);
      expect(model.completed, 80);
      expect(model.scheduled, 25);
      expect(model.total, 162);
    });

    test('parses live mobile-dashboard metrics endpoint response schema', () {
      final json = {
        'success': true,
        'data': {
          'newBookings': 0,
          'pendingBookings': 1,
          'scheduledBookings': 1,
          'todayScheduledBookings': 0,
          'upcomingInstallations': 0,
          'delayedBookings': 1,
          'completedBookings': 0,
          'cancelledBookings': 0,
          'totalBookings': 2,
          'period': 'this_month',
          'dateFrom': '2026-09-30T18:30:00.000Z',
          'dateTo': '2026-10-30T18:30:00.000Z',
        },
      };

      final model = DashboardModel.fromJson(json);
      expect(model.newBooking, 0);
      expect(model.pending, 1);
      expect(model.scheduled, 1);
      expect(model.completed, 0);
      expect(model.total, 2);
    });

    test('parses snake_case backend response and string numbers', () {
      final json = {
        'data': {
          'new_booking': '55',
          'pending': '12',
          'completed': '90',
          'scheduled': '30',
        },
      };

      final model = DashboardModel.fromJson(json);
      expect(model.newBooking, 55);
      expect(model.pending, 12);
      expect(model.completed, 90);
      expect(model.scheduled, 30);
      expect(model.total, 187);
    });

    test('parses list of status counts', () {
      final json = {
        'data': [
          {'status': 'New', 'count': 10},
          {'status': 'Pending', 'count': 4},
          {'status': 'Completed', 'count': 50},
          {'status': 'Scheduled', 'count': 20},
        ],
      };

      final model = DashboardModel.fromJson(json);
      expect(model.newBooking, 10);
      expect(model.pending, 4);
      expect(model.completed, 50);
      expect(model.scheduled, 20);
      expect(model.total, 84);
    });
  });

  group('DashboardService', () {
    test('passes correct query parameter for each period', () async {
      String? capturedQueryParam;

      final mockClient = MockClient((request) async {
        expect(request.url.origin + request.url.path, ApiConfig.dashboard);
        capturedQueryParam = request.url.queryParameters['period'];

        return http.Response(
          json.encode({
            'success': true,
            'data': {
              'newBooking': 10,
              'pending': 5,
              'completed': 20,
              'scheduled': 8,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = DashboardService(client: mockClient);

      await service.fetchDashboard(period: DashboardPeriod.currentMonth);
      expect(capturedQueryParam, 'this_month');

      await service.fetchDashboard(period: DashboardPeriod.last30Days);
      expect(capturedQueryParam, 'last_30_days');

      await service.fetchDashboard(period: DashboardPeriod.allTime);
      expect(capturedQueryParam, 'all');

      String? capturedDateFrom;
      String? capturedDateTo;
      final customMockClient = MockClient((request) async {
        capturedQueryParam = request.url.queryParameters['period'];
        capturedDateFrom = request.url.queryParameters['dateFrom'];
        capturedDateTo = request.url.queryParameters['dateTo'];
        return http.Response(
          json.encode({'data': {'newBooking': 2}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final customService = DashboardService(client: customMockClient);
      await customService.fetchDashboard(
        period: DashboardPeriod.custom,
        dateFrom: DateTime(2026, 10, 5),
        dateTo: DateTime(2026, 10, 20),
      );
      expect(capturedQueryParam, 'custom');
      expect(capturedDateFrom, '2026-10-05');
      expect(capturedDateTo, '2026-10-20');
    });
  });

  group('DashboardViewModel', () {
    test('loads data and updates state properly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'data': {
              'newBooking': 33,
              'pending': 7,
              'completed': 44,
              'scheduled': 19,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = DashboardViewModel(client: mockClient);
      expect(vm.isLoading, isFalse);
      expect(vm.dashboardData, isNull);

      final future = vm.fetchDashboard();
      expect(vm.isLoading, isTrue);

      await future;
      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
      expect(vm.dashboardData, isNotNull);
      expect(vm.newBookingMetric.value, '33');
      expect(vm.pendingMetric.value, '7');
      expect(vm.completedMetric.value, '44');
      expect(vm.scheduledMetric.value, '19');

      vm.dispose();
    });

    test('selectFilter updates selectedPeriod and triggers refetch', () async {
      String? requestedPeriod;
      final mockClient = MockClient((request) async {
        requestedPeriod = request.url.queryParameters['period'];
        return http.Response(
          json.encode({'data': {'newBooking': 1}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = DashboardViewModel(client: mockClient);
      vm.selectFilter('Last 30 Days');
      await Future.delayed(const Duration(milliseconds: 20));

      expect(vm.selectedPeriod, DashboardPeriod.last30Days);
      expect(requestedPeriod, 'last_30_days');

      vm.dispose();
    });

    test('setCustomDateRange updates custom period and passes date query params', () async {
      String? requestedPeriod;
      String? requestedDateFrom;
      String? requestedDateTo;

      final mockClient = MockClient((request) async {
        requestedPeriod = request.url.queryParameters['period'];
        requestedDateFrom = request.url.queryParameters['dateFrom'];
        requestedDateTo = request.url.queryParameters['dateTo'];
        return http.Response(
          json.encode({'data': {'newBooking': 5}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = DashboardViewModel(client: mockClient);
      vm.setCustomDateRange(DateTime(2026, 10, 5), DateTime(2026, 10, 20));
      await Future.delayed(const Duration(milliseconds: 20));

      expect(vm.selectedPeriod, DashboardPeriod.custom);
      expect(vm.customDateRange, isNotNull);
      expect(requestedPeriod, 'custom');
      expect(requestedDateFrom, '2026-10-05');
      expect(requestedDateTo, '2026-10-20');
      expect(vm.selectedFilter.startsWith('Custom (05/10 - 20/10)'), isTrue);

      vm.dispose();
    });
  });

  group('DashboardPage Widget Integration', () {
    testWidgets('renders skeleton while loading and cards once data arrives', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({
            'data': {
              'newBooking': 48,
              'pending': 19,
              'completed': 31,
              'scheduled': 35,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = DashboardViewModel(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardPage(viewModel: vm),
        ),
      );

      // Initially renders skeleton or loading state
      expect(find.byType(DashboardTimeFilterBar), findsOneWidget);

      await tester.pumpAndSettle();

      // After settling, renders the 4 MetricStatCards
      expect(find.byType(MetricStatCard), findsNWidgets(4));
      expect(find.text('48'), findsOneWidget);
      expect(find.text('19'), findsOneWidget);
      expect(find.text('31'), findsOneWidget);
      expect(find.text('35'), findsOneWidget);

      // Verify filter chips are rendered
      expect(find.text('Current Month'), findsOneWidget);
      expect(find.text('Last 30 Days'), findsOneWidget);
      expect(find.text('All Time'), findsOneWidget);
      expect(find.text('Custom'), findsOneWidget);

      vm.dispose();
    });

    testWidgets('tapping Custom chip opens input-mode date range dialog without full page', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          json.encode({'data': {'newBooking': 1}}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = DashboardViewModel(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardPage(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      expect(find.text('Select range'), findsOneWidget);
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('End Date'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      vm.dispose();
    });

    testWidgets('renders error view with retry button on failure', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final vm = DashboardViewModel(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: DashboardPage(viewModel: vm),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Retry'), findsOneWidget);
      expect(find.textContaining('Failed to load dashboard metrics'), findsOneWidget);

      vm.dispose();
    });

    testWidgets('BottomNavigator refreshes dashboard every time dashboard tab is selected', (tester) async {
      int dashboardFetchCount = 0;
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('dashboard')) {
          dashboardFetchCount++;
          return http.Response(
            json.encode({
              'status': 'success',
              'data': {'newBooking': 10},
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{"data": []}', 200, headers: {'content-type': 'application/json'});
      });

      final dvm = DashboardViewModel(client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: BottomNavigator(dashboardViewModel: dvm),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Initial load: Dashboard is mounted in IndexedStack
      expect(dashboardFetchCount, 1);

      // Select Dashboard tab (index 1)
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dashboard was refreshed!
      expect(dashboardFetchCount, 2);

      // Switch to Today tab (index 0)
      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Select Dashboard tab again
      await tester.tap(find.byIcon(Icons.chat_bubble_outline_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dashboard was refreshed again!
      expect(dashboardFetchCount, 3);
    });
  });

  group('PermanentSlashDateInputFormatter & CustomDateRangePickerDialog', () {
    test('formatter maintains permanent slashes and inserts them on digit entry', () {
      final formatter = PermanentSlashDateInputFormatter();

      // Enter first 2 digits
      var result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(text: '10', selection: TextSelection.collapsed(offset: 2)),
      );
      expect(result.text, '10/');
      expect(result.selection.end, 3);

      // Enter next 2 digits
      result = formatter.formatEditUpdate(
        result,
        const TextEditingValue(text: '10/06', selection: TextSelection.collapsed(offset: 5)),
      );
      expect(result.text, '10/06/');
      expect(result.selection.end, 6);

      // Enter year digits
      result = formatter.formatEditUpdate(
        result,
        const TextEditingValue(text: '10/06/2026', selection: TextSelection.collapsed(offset: 10)),
      );
      expect(result.text, '10/06/2026');
      expect(result.selection.end, 10);
    });

    test('formatter cleanly deletes preceding digit when backspacing over a slash', () {
      final formatter = PermanentSlashDateInputFormatter();

      final current = const TextEditingValue(
        text: '10/06/',
        selection: TextSelection.collapsed(offset: 6),
      );

      // Backspace deleting the slash
      final backspaced = formatter.formatEditUpdate(
        current,
        const TextEditingValue(text: '10/06', selection: TextSelection.collapsed(offset: 5)),
      );

      // Should delete the digit '6' before the slash, resulting in '10/0'
      expect(backspaced.text, '10/0');
      expect(backspaced.selection.end, 4);
    });

    testWidgets('CustomDateRangePickerDialog allows editing dates and submitting range', (tester) async {
      DateTimeRange? submittedRange;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    submittedRange = await showCustomDateRangePicker(
                      context: context,
                      initialDateRange: DateTimeRange(
                        start: DateTime(2023, 10, 6),
                        end: DateTime(2026, 10, 28),
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        ),
      );

      // Open dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify header matches screenshot: "Oct 6, 2023 – Oct 28, 2026"
      expect(find.text('Oct 6, 2023 – Oct 28, 2026'), findsOneWidget);
      expect(find.text('10/06/2023'), findsOneWidget);
      expect(find.text('10/28/2026'), findsOneWidget);

      // Confirm dialog by tapping OK
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(submittedRange, isNotNull);
      expect(submittedRange!.start, DateTime(2023, 10, 6));
      expect(submittedRange!.end, DateTime(2026, 10, 28));
    });
  });
}

