import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/api/api.dart';
import 'package:task_chat/dashboard/dashboard_model.dart';
import 'package:task_chat/dashboard/dashboard_view.dart';
import 'package:task_chat/dashboard/dashboard_view_model.dart';
import 'package:task_chat/dashboard/widgets/dashboard_time_filter_bar.dart';
import 'package:task_chat/dashboard/widgets/metric_stat_card.dart';
import 'package:task_chat/bottom_navigator/bottom_navigator.dart';

void main() {
  group('DashboardPeriod Mapping', () {
    test('queryValue maps correctly according to requirements', () {
      expect(DashboardPeriod.currentMonth.queryValue, 'this_month');
      expect(DashboardPeriod.last30Days.queryValue, 'last_30_days');
      expect(DashboardPeriod.allTime.queryValue, 'all');
    });

    test('fromLabel parses various label strings', () {
      expect(DashboardPeriod.fromLabel('Current Month'), DashboardPeriod.currentMonth);
      expect(DashboardPeriod.fromLabel('This Month'), DashboardPeriod.currentMonth);
      expect(DashboardPeriod.fromLabel('Last 30 Days'), DashboardPeriod.last30Days);
      expect(DashboardPeriod.fromLabel('All Time'), DashboardPeriod.allTime);
      expect(DashboardPeriod.fromLabel('All'), DashboardPeriod.allTime);
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
}
