import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/api/api.dart';
import 'package:task_chat/core/widgets/app_pill_notification.dart';
import 'package:task_chat/login_page/token_storage.dart';
import 'package:task_chat/report_activity/activity/activity_model.dart';
import 'package:task_chat/report_activity/activity/activity_view.dart';
import 'package:task_chat/report_activity/activity/activity_view_model.dart';
import 'package:task_chat/report_activity/activity/booking_history_page.dart';
import 'package:task_chat/report_activity/main/report_activity.dart';
import 'package:task_chat/report_activity/widgets/activity_item_card.dart';
import 'package:task_chat/report_activity/widgets/activity_skeleton_loading.dart';
import 'package:task_chat/report_activity/report/report_model.dart';
import 'package:task_chat/report_activity/report/report_view.dart';
import 'package:task_chat/report_activity/report/report_view_model.dart';
import 'package:task_chat/report_activity/widgets/report_date_range_bar.dart';
import 'package:task_chat/report_activity/widgets/status_activity_graph_card.dart';
import 'package:task_chat/report_activity/widgets/weekly_activity_graph_card.dart';

void main() {
  setUp(() {
    TokenStorage.useMemoryOnly = true;
  });

  group('ActivityModel Tests', () {
    test('ActivityModel.fromJson parses fields correctly', () {
      final jsonSample = {
        'id': '101',
        'clientName': 'Devika',
        'status': 'Completed',
        'scheduleDate': '2026-10-24T12:44:58.000Z',
        'notes': 'Payment received in full',
        'createdByName': 'Sita Sharma',
        'areaName': 'Kowdiar',
      };

      final model = ActivityModel.fromJson(jsonSample);

      expect(model.id, equals('101'));
      expect(model.title, equals('Devika'));
      expect(model.avatarLetter, equals('D'));
      expect(model.statusTag, equals('Completed'));
      expect(model.noteText, equals('Payment received in full'));
      expect(model.subtitlePrefix, equals('Updated by '));
      expect(model.subtitleHighlight, equals('Sita Sharma'));
      expect(model.location, equals('Kowdiar'));
      expect(model.isPending, isFalse);
    });

    test('ActivityModel.fromJson handles fallback when fields are missing', () {
      final jsonSample = <String, dynamic>{};
      final model = ActivityModel.fromJson(jsonSample);

      expect(model.title, equals('Client'));
      expect(model.avatarLetter, equals('C'));
      expect(model.statusTag, equals('New'));
      expect(model.isPending, isTrue);
    });

    test(
      'ActivityModel.fromJson parses backend booking-history response structure',
      () {
        final jsonSample = {
          "history_id": 31,
          "booking_id": 25,
          "booking_name": "test notes",
          "action_type": "New Booking Created",
          "customer_note": "test notes",
          "staff_note": null,
          "new_status_id": 1,
          "new_status_code": "New",
          "new_status_label": "New",
          "new_status_color_code": "#3b82f6",
          "to_branch_head_id": 6,
          "to_branch_head_name": "Anas Kabeer",
          "to_assigned_head_district_name": "Kozhikode",
          "action_by_id": 1,
          "action_by_name": "SteelGuard Executive Board",
          "action_by_role_id": 3,
          "created_at": "2026-10-29T08:52:24.000Z",
        };

        final model = ActivityModel.fromJson(jsonSample);

        expect(model.id, equals('31'));
        expect(model.title, equals('test notes'));
        expect(model.statusTag, equals('New'));
        expect(model.avatarLetter, equals('T'));
        expect(model.statusTagTextColor, equals(const Color(0xFF3B82F6)));
        expect(model.subtitlePrefix, equals('Branch Manager: '));
        expect(model.subtitleHighlight, equals('SteelGuard Executive Board'));
        expect(model.noteText, equals('test notes'));
        expect(model.location, equals('Kozhikode'));
      },
    );
  });

  group('ActivityViewModel Tests', () {
    test(
      'fetchHistory calls ApiConfig.history_list and updates activities',
      () async {
        final mockData = {
          'success': true,
          'data': {
            'history': [
              {
                'id': 1,
                'clientName': 'Arun',
                'status': 'Cancelled',
                'notes': 'Rescheduled to monday',
                'scheduleDate': '2026-10-29T10:00:00.000Z',
              },
              {
                'id': 2,
                'clientName': 'Devika',
                'status': 'Completed',
                'notes': 'Done on time',
                'scheduleDate': '2026-10-29T11:00:00.000Z',
              },
            ],
            'count': 2,
          },
        };

        final client = MockClient((request) async {
          expect(request.url.toString(), equals(ApiConfig.history_list));
          return http.Response(
            jsonEncode(mockData),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final vm = ActivityViewModel(client: client);
        expect(vm.isLoading, isFalse);

        await vm.fetchHistory();

        expect(vm.isLoading, isFalse);
        expect(vm.activities.length, equals(2));
        expect(vm.activities[0].title, equals('Arun'));
        expect(vm.activities[1].title, equals('Devika'));
        expect(vm.errorMessage, isNull);
      },
    );

    test('Filtering by status and searching works as expected', () async {
      final mockData = {
        'success': true,
        'data': {
          'history': [
            {
              'id': 1,
              'clientName': 'Arun',
              'status': 'Cancelled',
              'notes': 'Rescheduled to monday',
              'scheduleDate': DateTime.now().toIso8601String(),
            },
            {
              'id': 2,
              'clientName': 'Devika',
              'status': 'Completed',
              'notes': 'Done on time',
              'scheduleDate': DateTime.now().toIso8601String(),
            },
          ],
        },
      };

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(mockData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = ActivityViewModel(client: client);
      await vm.fetchHistory();

      expect(vm.filteredActivities.length, equals(2));

      // Filter by status: Completed
      vm.setStatusFilter('Completed');
      expect(vm.filteredActivities.length, equals(1));
      expect(vm.filteredActivities.first.title, equals('Devika'));

      // Reset status
      vm.setStatusFilter('All');
      expect(vm.filteredActivities.length, equals(2));

      // Search query
      vm.setSearchQuery('Arun', immediate: true);
      expect(vm.filteredActivities.length, equals(1));
      expect(vm.filteredActivities.first.title, equals('Arun'));

      // Time filters: 'All' shows all items, and switching works
      vm.setSearchQuery('', immediate: true);
      expect(vm.filters.first, equals('All'));
      expect(vm.selectedFilterIndex, equals(0));
      expect(vm.filteredActivities.length, equals(2));
    });

    test('ActivityViewModel.extractHistoryList parses various payload structures', () {
      final sampleList = [{'history_id': 1}];

      // 1. { data: [ ... ] }
      expect(
        ActivityViewModel.extractHistoryList({'status': true, 'data': sampleList})?.length,
        equals(1),
      );

      // 2. { data: { history: [ ... ] } }
      expect(
        ActivityViewModel.extractHistoryList({'data': {'history': sampleList}})?.length,
        equals(1),
      );

      // 3. { items: [ ... ] }
      expect(
        ActivityViewModel.extractHistoryList({'items': sampleList})?.length,
        equals(1),
      );

      // 4. Raw list [ ... ]
      expect(
        ActivityViewModel.extractHistoryList(sampleList)?.length,
        equals(1),
      );
    });

    test('fetchHistory handles HTTP error cleanly', () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final vm = ActivityViewModel(client: client);
      await vm.fetchHistory();

      expect(vm.activities.isEmpty, isTrue);
      expect(vm.errorMessage, contains('Failed to load'));
    });

    test('ActivityViewModel parses response with page, limit, and count correctly', () async {
      final mockData = {
        'success': true,
        'data': {
          'history': [
            {
              'history_id': 31756,
              'booking_id': 10008,
              'booking_name': 'rija customer',
              'action_type': 'Status Updated',
              'customer_note': null,
              'staff_note': 'assassaaaaa',
              'old_status_id': 3,
              'old_status_code': 'Completed',
              'old_status_label': 'Completed',
              'old_status_color_code': '#10b981',
              'new_status_id': 4,
              'new_status_code': 'Cancelled',
              'new_status_label': 'Cancelled',
              'new_status_color_code': '#ef4444',
              'action_by_id': 15,
              'action_by_name': 'Company Executive 1',
              'action_by_role_id': 1,
              'created_at': '2026-11-04T03:58:27.000Z',
            },
            {
              'history_id': 31752,
              'booking_id': 10010,
              'booking_name': 'casds',
              'action_type': 'New Booking Created',
              'customer_note': '3245',
              'staff_note': null,
              'new_status_id': 1,
              'new_status_code': 'New',
              'new_status_label': 'New',
              'new_status_color_code': '#3b82f6',
              'action_by_id': 85,
              'action_by_name': 'Steel Doors Dealer 1',
              'action_by_role_id': 4,
              'created_at': '2026-11-04T03:53:12.000Z',
            },
          ],
          'page': 1,
          'limit': 20,
          'count': 8,
        },
      };

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(mockData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = ActivityViewModel(client: client);
      await vm.fetchHistory();

      expect(vm.currentPage, equals(1));
      expect(vm.limit, equals(20));
      expect(vm.totalCount, equals(8));
      expect(vm.activities.length, equals(2));
      expect(vm.activities[0].title, equals('rija customer'));
      expect(vm.activities[1].title, equals('casds'));
      // Since 2 items returned is less than limit (20), hasMore should be false
      expect(vm.hasMore, isFalse);
    });

    test('ActivityViewModel.loadNextPage sends page=2&limit=20 and appends activities', () async {
      int requestCount = 0;
      final client = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'history': List.generate(
                  20,
                  (i) => {
                    'history_id': 1000 + i,
                    'booking_id': 100 + i,
                    'booking_name': 'Customer $i',
                    'new_status_label': 'Completed',
                    'action_by_name': 'Coordinator 1',
                    'action_by_role_id': 2,
                    'created_at': DateTime.now().toIso8601String(),
                  },
                ),
                'page': 1,
                'limit': 20,
                'count': 35,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        } else {
          expect(request.url.queryParameters['page'], equals('2'));
          expect(request.url.queryParameters['limit'], equals('20'));
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'history': List.generate(
                  15,
                  (i) => {
                    'history_id': 2000 + i,
                    'booking_id': 200 + i,
                    'booking_name': 'Customer Page 2 - $i',
                    'new_status_label': 'Scheduled',
                    'action_by_name': 'Coordinator 1',
                    'action_by_role_id': 2,
                    'created_at': '2026-11-04T04:00:00.000Z',
                  },
                ),
                'page': 2,
                'limit': 20,
                'count': 35,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
      });

      final vm = ActivityViewModel(client: client);
      await vm.fetchHistory();

      expect(vm.currentPage, equals(1));
      expect(vm.activities.length, equals(20));
      expect(vm.hasMore, isTrue);

      await vm.loadNextPage();

      expect(vm.currentPage, equals(2));
      expect(vm.activities.length, equals(35));
      expect(vm.hasMore, isFalse); // Total 35 items loaded which equals totalCount
    });

    test('ActivityViewModel.fetchHistoryByBookingId requests report_graph_bybookingid endpoint and returns list', () async {
      final client = MockClient((request) async {
        expect(
          request.url.toString(),
          equals(ApiConfig.reportGraphByBookingId('10008')),
        );
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'booking_id': 10008,
              'page': 1,
              'limit': 10,
              'count': 2,
              'history': [
                {
                  'history_id': 31753,
                  'booking_id': 10008,
                  'booking_name': 'test wa',
                  'action_type': 'Transfered',
                  'customer_note': null,
                  'staff_note': 'staff notes',
                  'from_assigned_head_district_name': 'Wayanad',
                  'to_assigned_head_district_name': 'Wayanad',
                  'action_by_id': 35,
                  'action_by_name': 'Coordinator Officer 1',
                  'action_by_role_id': 2,
                  'created_at': '2026-11-03T10:43:34.000Z',
                },
                {
                  'history_id': 31750,
                  'booking_id': 10008,
                  'booking_name': 'test wa',
                  'action_type': 'New Booking Created',
                  'customer_note': '',
                  'staff_note': null,
                  'new_status_id': 1,
                  'new_status_code': 'New',
                  'new_status_label': 'New',
                  'new_status_color_code': '#3b82f6',
                  'to_assigned_head_district_name': 'Wayanad',
                  'action_by_id': 35,
                  'action_by_name': 'Coordinator Officer 1',
                  'action_by_role_id': 2,
                  'created_at': '2026-11-03T07:21:08.000Z',
                },
              ],
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = ActivityViewModel(client: client);
      final history = await vm.fetchHistoryByBookingId(10008);

      expect(history, isNotNull);
      expect(history!.length, equals(2));
      expect(history.first['history_id'], equals(31753));
      expect(history.first['action_type'], equals('Transfered'));
      expect(history.last['action_type'], equals('New Booking Created'));
    });
  });

  group('ReportActivity UI Tests', () {
    testWidgets(
      'ReportActivity renders 2 menu cards: Task Report and Activity, and navigates to ActivityPage',
      (tester) async {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'history': [
                  {
                    'id': 1,
                    'clientName': 'Devika',
                    'status': 'Completed',
                    'scheduleDate': DateTime.now().toIso8601String(),
                  },
                ],
                'count': 1,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final activityVm = ActivityViewModel(client: client);

        await tester.pumpWidget(
          MaterialApp(home: ReportActivity(activityViewModel: activityVm)),
        );

        await tester.pumpAndSettle();

        // Check both section menu cards are rendered
        expect(find.text('Task Report'), findsOneWidget);
        expect(find.text('Activity'), findsOneWidget);

        // Tap on 'Activity' menu card
        await tester.tap(find.text('Activity'));
        await tester.pumpAndSettle();

        // Verify ActivityPage is displayed with the live history items
        expect(find.byType(ActivityView), findsOneWidget);
        expect(find.text('Devika'), findsOneWidget);
      },
    );

    testWidgets(
      'ReportActivity navigates to TaskReportPage on tapping Task Report card',
      (tester) async {
        final mockReportData = {
          'success': true,
          'data': [],
        };
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode(mockReportData),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final reportVm = ReportViewModel(client: client);

        await tester.pumpWidget(
          MaterialApp(home: ReportActivity(reportViewModel: reportVm)),
        );

        await tester.pumpAndSettle();

        // Tap on 'Task Report' menu card
        await tester.tap(find.text('Task Report'));
        await tester.pumpAndSettle();

        // Verify TaskReportPage (ReportView) is displayed
        expect(find.byType(ReportView), findsOneWidget);
        expect(find.text('New Bookings'), findsOneWidget);
      },
    );

    testWidgets(
      'ActivitySkeletonLoading renders skeleton cards with animation',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ActivitySkeletonLoading(itemCount: 3)),
          ),
        );

        expect(find.byType(ActivitySkeletonLoading), findsOneWidget);
        // Pump animation tick
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(ActivityCardSkeleton), findsNWidgets(3));
      },
    );

    testWidgets(
      'ActivityItemCard renders title, status, and actor, but does not display notes',
      (tester) async {
        final item = ActivityModel(
          id: '99',
          title: 'Special Client',
          avatarLetter: 'S',
          avatarBgColor: const Color(0xFFE2E8F0),
          avatarTextColor: const Color(0xFF1E293B),
          date: 'Today',
          statusTag: 'Completed',
          subtitlePrefix: 'Branch Manager: ',
          subtitleHighlight: 'Anas Kabeer',
          noteText: 'Confidential Internal Note',
          notes: 'Confidential Internal Note',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityItemCard(item: item),
            ),
          ),
        );

        expect(find.text('Special Client'), findsOneWidget);
        expect(find.text('Completed'), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is RichText &&
                widget.text.toPlainText().contains('Anas Kabeer'),
          ),
          findsOneWidget,
        );
        // Notes should NOT be present in UI
        expect(find.textContaining('Confidential Internal Note'), findsNothing);

        // Person icon should be rendered instead of letter initials
        expect(find.byIcon(Icons.person_rounded), findsOneWidget);
        expect(find.text('S'), findsNothing);
      },
    );

    testWidgets(
      'ActivityView displays scroll-to-top pop up arrow button when scrolled down and scrolls to top on tap',
      (tester) async {
        final mockItems = List.generate(
          25,
          (i) => {
            'history_id': 1000 + i,
            'booking_id': 100 + i,
            'booking_name': 'Customer Activity $i',
            'new_status_label': 'Completed',
            'action_by_name': 'Executive',
            'action_by_role_id': 1,
            'created_at': DateTime.now().toIso8601String(),
          },
        );

        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'history': mockItems,
                'page': 1,
                'limit': 20,
                'count': 50,
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final vm = ActivityViewModel(client: client);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityView(viewModel: vm),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially at top (pixels = 0), scroll-to-top button should not be scaled up
        final btnFinder = find.byKey(const Key('activity_scroll_to_top_button'));
        expect(btnFinder, findsOneWidget);

        final animatedScaleWidget = tester.widget<AnimatedScale>(btnFinder);
        expect(animatedScaleWidget.scale, equals(0.0));

        // Scroll down by dragging a list item
        await tester.drag(find.text('Customer Activity 1'), const Offset(0, -600));
        await tester.pumpAndSettle();

        final animatedScaleScrolled = tester.widget<AnimatedScale>(btnFinder);
        expect(animatedScaleScrolled.scale, equals(1.0));

        // Tap scroll-to-top button
        await tester.tap(btnFinder);
        await tester.pumpAndSettle();

        // Scroll offset should return to 0
        final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).last);
        expect(scrollable.position.pixels, equals(0.0));
      },
    );

    testWidgets(
      'Tapping ActivityItemCard opens BookingHistoryPage with timeline demonstrating status, notes, branch head, and schedule date changes',
      (tester) async {
        final booking = ActivityModel(
          id: '23',
          bookingId: 23,
          title: 'test',
          avatarLetter: 'T',
          avatarBgColor: const Color(0xFFDCFCE7),
          avatarTextColor: const Color(0xFF16A34A),
          date: '29/10/2026',
          statusTag: 'Completed',
          subtitlePrefix: 'Branch Manager: ',
          subtitleHighlight: 'Anas Kabeer (Kozhikode)',
          notes: 'Call 30 min before arriving, use the side gate',
        );

        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'booking_id': 23,
                'history': [
                  {
                    'history_id': 5,
                    'booking_id': 23,
                    'booking_name': 'test',
                    'action_type': 'Booking Completed',
                    'action_by_name': 'Anas Kabeer (Kozhikode)',
                    'old_status_label': 'Scheduled',
                    'new_status_label': 'Completed',
                    'old_status_color_code': '#f59e0b',
                    'new_status_color_code': '#22c55e',
                    'created_at': '2026-10-29T17:35:00Z',
                  },
                  {
                    'history_id': 4,
                    'booking_id': 23,
                    'booking_name': 'test',
                    'action_type': 'Booking Rescheduled',
                    'action_by_name': 'Anas Kabeer (Kozhikode)',
                    'new_status_label': 'Edited',
                    'old_schedule_date': '2026-10-30T00:00:00Z',
                    'new_schedule_date': '2026-11-02T00:00:00Z',
                    'created_at': '2026-10-29T17:20:00Z',
                  },
                  {
                    'history_id': 3,
                    'booking_id': 23,
                    'booking_name': 'test',
                    'old_booking_name': 'tes',
                    'new_booking_name': 'test',
                    'action_type': 'Details Updated',
                    'action_by_name': 'Anas Kabeer (Kozhikode)',
                    'new_status_label': 'Edited',
                    'old_notes': 'Call before arriving',
                    'notes': 'Call 30 min before arriving, use the side gate',
                    'created_at': '2026-10-29T17:05:00Z',
                  },
                  {
                    'history_id': 2,
                    'booking_id': 23,
                    'booking_name': 'test',
                    'action_type': 'Booking Scheduled',
                    'action_by_name': 'Anas Kabeer (Kozhikode)',
                    'from_branch_head_name': 'Unassigned',
                    'to_branch_head_name': 'Anas Kabeer (Kozhikode)',
                    'old_status_label': 'New',
                    'new_status_label': 'Scheduled',
                    'created_at': '2026-10-29T16:50:00Z',
                  },
                  {
                    'history_id': 1,
                    'booking_id': 23,
                    'booking_name': 'test',
                    'action_type': 'New Booking Created',
                    'action_by_name': 'Anas Kabeer (Kozhikode)',
                    'new_status_label': 'New',
                    'created_at': '2026-10-29T16:30:00Z',
                  },
                ],
              },
            }),
            200,
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityView(
                viewModel: ActivityViewModel(
                  client: mockClient,
                ),
              ),
            ),
          ),
        );

        // Directly pump BookingHistoryPage
        await tester.pumpWidget(
          MaterialApp(
            home: BookingHistoryPage(
              initialBooking: booking,
              allActivities: [booking],
              client: mockClient,
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verify Top Bar Header
        expect(find.text('History'), findsOneWidget);

        // 2. Verify Accordion Booking Header
        expect(find.text('test'), findsNWidgets(2)); // in header title and in NAME diff
        expect(find.text('#23'), findsOneWidget);
        expect(find.text('5 updates'), findsOneWidget);

        // 3. Verify Timeline Milestones
        expect(find.text('Booking Completed'), findsOneWidget);
        expect(find.text('CURRENT'), findsOneWidget);
        expect(find.text('Booking Rescheduled'), findsOneWidget);
        expect(find.text('Details Updated'), findsOneWidget);
        expect(find.text('Booking Scheduled'), findsOneWidget);
        expect(find.text('New Booking Created'), findsOneWidget);

        // 4. Verify Diff Fields (Schedule Date, Notes, Branch Head, Status)
        expect(find.text('SCHEDULED DATE'), findsOneWidget);
        expect(find.text('30/10/2026'), findsOneWidget);
        expect(find.text('02/11/2026'), findsOneWidget);

        expect(find.text('NOTES'), findsOneWidget);
        expect(find.textContaining('Call before arriving'), findsOneWidget);
        expect(
          find.text('Call 30 min before arriving, use the side gate'),
          findsOneWidget,
        );

        expect(find.text('BRANCH HEAD'), findsOneWidget);
        expect(find.text('Unassigned'), findsOneWidget);
        expect(find.text('Anas Kabeer (Kozhikode)'), findsOneWidget);

        expect(find.text('STATUS'), findsWidgets);
      },
    );

    testWidgets(
      'BookingHistoryPage fetches report_graph_bybookingid API on load and displays events',
      (tester) async {
        final booking = ActivityModel(
          id: '10008',
          bookingId: 10008,
          title: 'test wa',
          avatarLetter: 'T',
          avatarBgColor: const Color(0xFFDCFCE7),
          avatarTextColor: const Color(0xFF16A34A),
          date: '03/11/2026',
          statusTag: 'Completed',
        );

        final client = MockClient((request) async {
          expect(
            request.url.toString(),
            equals(ApiConfig.reportGraphByBookingId('10008')),
          );
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'booking_id': 10008,
                'page': 1,
                'limit': 10,
                'count': 2,
                'history': [
                  {
                    'history_id': 31753,
                    'booking_id': 10008,
                    'booking_name': 'test wa',
                    'action_type': 'Transfered',
                    'customer_note': null,
                    'staff_note': 'staff notes',
                    'from_assigned_head_district_name': 'Wayanad',
                    'to_assigned_head_district_name': 'Wayanad',
                    'action_by_id': 35,
                    'action_by_name': 'Coordinator Officer 1',
                    'action_by_role_id': 2,
                    'created_at': '2026-11-03T10:43:34.000Z',
                  },
                  {
                    'history_id': 31750,
                    'booking_id': 10008,
                    'booking_name': 'test wa',
                    'action_type': 'New Booking Created',
                    'customer_note': '',
                    'staff_note': null,
                    'new_status_id': 1,
                    'new_status_code': 'New',
                    'new_status_label': 'New',
                    'new_status_color_code': '#3b82f6',
                    'to_assigned_head_district_name': 'Wayanad',
                    'action_by_id': 35,
                    'action_by_name': 'Coordinator Officer 1',
                    'action_by_role_id': 2,
                    'created_at': '2026-11-03T07:21:08.000Z',
                  },
                ],
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        await tester.pumpWidget(
          MaterialApp(
            home: BookingHistoryPage(
              initialBooking: booking,
              client: client,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('History'), findsOneWidget);
        expect(find.text('test wa'), findsOneWidget);
        expect(find.text('2 updates'), findsOneWidget);
        expect(find.text('Transfered'), findsNWidgets(2)); // badge & action title
        expect(find.text('New Booking Created'), findsOneWidget);
        expect(find.text('staff notes'), findsOneWidget);
      },
    );

    testWidgets(
      'BookingHistoryPage only shows the clicked user history and excludes other users',
      (tester) async {
        final clickedUser = ActivityModel(
          id: '10',
          bookingId: 10,
          title: 'Selected User',
          avatarLetter: 'S',
          avatarBgColor: const Color(0xFFDCFCE7),
          avatarTextColor: const Color(0xFF16A34A),
          date: '29/10/2026',
          statusTag: 'Completed',
        );

        final otherUser1 = ActivityModel(
          id: '20',
          bookingId: 20,
          title: 'Other User One',
          avatarLetter: 'O',
          avatarBgColor: const Color(0xFFDBEAFE),
          avatarTextColor: const Color(0xFF1D4ED8),
          date: '29/10/2026',
          statusTag: 'New',
        );

        final otherUser2 = ActivityModel(
          id: '30',
          bookingId: 30,
          title: 'Other User Two',
          avatarLetter: 'T',
          avatarBgColor: const Color(0xFFFEF3C7),
          avatarTextColor: const Color(0xFFD97706),
          date: '29/10/2026',
          statusTag: 'Scheduled',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: BookingHistoryPage(
              initialBooking: clickedUser,
              allActivities: [clickedUser, otherUser1, otherUser2],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Selected user IS present
        expect(find.text('Selected User'), findsWidgets);
        expect(find.text('#10'), findsOneWidget);

        // Other users MUST NOT be present
        expect(find.text('Other User One'), findsNothing);
        expect(find.text('#20'), findsNothing);
        expect(find.text('Other User Two'), findsNothing);
        expect(find.text('#30'), findsNothing);
      },
    );
  });

  group('AppNotification Tests', () {
    testWidgets('AppPillNotification renders message in compact capsule design',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppPillNotification(
              message: 'Send a message to your contact',
            ),
          ),
        ),
      );

      expect(find.text('Send a message to your contact'), findsOneWidget);
      expect(find.byType(AppPillNotification), findsOneWidget);
    });

    testWidgets(
        'AppNotification.showStatusChange triggers floating capsule snackbar',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppNotification.showStatusChange(
                    context,
                    status: 'Scheduled',
                    customerName: 'Anas Kabeer',
                  );
                },
                child: const Text('Change Status'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Change Status'));
      await tester.pumpAndSettle();

      expect(
        find.text('Status updated to Scheduled for Anas Kabeer'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });
  });

  group('Weekly Activity Report Graph Tests', () {
    test('BookingReportGraphItem.fromJson parses example API json correctly', () {
      final json = {
        'periodLabel': 'Mon',
        'periodDate': '2026-11-02',
        'newCount': 15,
        'scheduledCount': 11,
        'completedCount': 9,
        'cancelledCount': 3,
        'totalActivities': 38,
      };

      final item = BookingReportGraphItem.fromJson(json);

      expect(item.periodLabel, equals('Mon'));
      expect(item.periodDate, equals('2026-11-02'));
      expect(item.newCount, equals(15));
      expect(item.scheduledCount, equals(11));
      expect(item.completedCount, equals(9));
      expect(item.cancelledCount, equals(3));
      expect(item.totalActivities, equals(38));
    });

    test('ReportViewModel.fetchGraphReport calls ApiConfig.report_graph and updates graphData', () async {
      final mockData = {
        'success': true,
        'data': [
          {
            'periodLabel': 'Mon',
            'periodDate': '2026-11-02',
            'newCount': 15,
            'scheduledCount': 11,
            'completedCount': 9,
            'cancelledCount': 3,
            'totalActivities': 38,
          },
          {
            'periodLabel': 'Tue',
            'periodDate': '2026-11-03',
            'newCount': 12,
            'scheduledCount': 10,
            'completedCount': 8,
            'cancelledCount': 2,
            'totalActivities': 32,
          },
        ],
      };

      final client = MockClient((request) async {
        expect(request.url.path, equals(Uri.parse(ApiConfig.report_graph).path));
        expect(request.url.queryParameters['dateFrom'], equals(ReportViewModel.defaultDateFrom));
        expect(request.url.queryParameters['dateTo'], equals(ReportViewModel.defaultDateTo));
        return http.Response(
          jsonEncode(mockData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = ReportViewModel(client: client);
      expect(vm.isGraphLoading, isFalse);

      await vm.fetchGraphReport();

      expect(vm.isGraphLoading, isFalse);
      expect(vm.graphData.length, equals(2));
      expect(vm.graphData[0].periodLabel, equals('Mon'));
      expect(vm.graphData[0].newCount, equals(15));
      expect(vm.graphData[1].periodLabel, equals('Tue'));
      expect(vm.graphErrorMessage, isNull);
    });

    testWidgets('WeeklyActivityGraphCard renders header, legend, and day labels', (tester) async {
      final items = [
        const BookingReportGraphItem(
          periodLabel: 'Mon',
          periodDate: '2026-11-02',
          newCount: 15,
          scheduledCount: 11,
          completedCount: 9,
          cancelledCount: 3,
          totalActivities: 38,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeeklyActivityGraphCard(graphData: items),
            ),
          ),
        ),
      );

      expect(find.text('Weekly activity'), findsOneWidget);
      expect(find.text('Mon to Sun, by status'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);

      // By default, Monday info is displayed below the graph
      expect(find.text('Mon (2026-11-02)'), findsOneWidget);
      expect(find.text('Total: 38'), findsOneWidget);
      // '15' appears on the dynamic Y-axis tick mark and in the breakdown card below
      expect(find.text('15'), findsNWidgets(2));
      expect(find.text('11'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Verify status breakdown items are present for each status
      expect(find.text('New'), findsWidgets);
      expect(find.text('Scheduled'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Cancelled'), findsWidgets);
    });

    testWidgets('WeeklyActivityGraphCard dynamically adapts Y-axis to max count', (tester) async {
      // Small data with max count = 8
      final smallItems = [
        const BookingReportGraphItem(
          periodLabel: 'Wed',
          periodDate: '2026-11-04',
          newCount: 8,
          scheduledCount: 4,
          completedCount: 2,
          cancelledCount: 1,
          totalActivities: 15,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeeklyActivityGraphCard(graphData: smallItems),
            ),
          ),
        ),
      );

      // Y-axis dynamically scales to 8 instead of hardcoded 20
      expect(find.text('8'), findsNWidgets(2)); // Tick mark + count
      expect(find.text('20'), findsNothing); // 20 does not appear
    });

    testWidgets('WeeklyActivityGraphCard makes graph horizontally scrollable when data count > 3', (tester) async {
      final weekItems = [
        const BookingReportGraphItem(periodLabel: 'Mon', periodDate: '2026-11-02', newCount: 10, scheduledCount: 8, completedCount: 5, cancelledCount: 2, totalActivities: 25),
        const BookingReportGraphItem(periodLabel: 'Tue', periodDate: '2026-11-03', newCount: 12, scheduledCount: 6, completedCount: 4, cancelledCount: 1, totalActivities: 23),
        const BookingReportGraphItem(periodLabel: 'Wed', periodDate: '2026-11-04', newCount: 8, scheduledCount: 9, completedCount: 7, cancelledCount: 3, totalActivities: 27),
        const BookingReportGraphItem(periodLabel: 'Thu', periodDate: '2026-11-05', newCount: 14, scheduledCount: 11, completedCount: 8, cancelledCount: 2, totalActivities: 35),
        const BookingReportGraphItem(periodLabel: 'Fri', periodDate: '2026-11-06', newCount: 18, scheduledCount: 14, completedCount: 12, cancelledCount: 4, totalActivities: 48),
        const BookingReportGraphItem(periodLabel: 'Sat', periodDate: '2026-11-07', newCount: 7, scheduledCount: 5, completedCount: 3, cancelledCount: 1, totalActivities: 16),
        const BookingReportGraphItem(periodLabel: 'Sun', periodDate: '2026-11-08', newCount: 3, scheduledCount: 2, completedCount: 1, cancelledCount: 0, totalActivities: 6),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeeklyActivityGraphCard(graphData: weekItems),
            ),
          ),
        ),
      );

      // Verify horizontal SingleChildScrollView exists for chart content (> 3 items) and legend
      final horizontalScrollFinder = find.byWidgetPredicate(
        (widget) =>
            widget is SingleChildScrollView &&
            widget.scrollDirection == Axis.horizontal,
      );
      expect(horizontalScrollFinder, findsNWidgets(2));

      // Verify all 7 day labels are present in the widget tree
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);
      expect(find.text('Wed'), findsOneWidget);
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
      expect(find.text('Sat'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
    });

    testWidgets('WeeklyActivityGraphCard renders GraphSkeletonLoading when isLoading is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: WeeklyActivityGraphCard(
                graphData: [],
                isLoading: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GraphSkeletonLoading), findsOneWidget);
    });

    testWidgets('ReportView renders status activity graph cards and fetches report', (tester) async {
      final mockData = {
        'success': true,
        'data': [
          {
            'periodLabel': 'Mon',
            'periodDate': '2026-11-02',
            'newCount': 15,
            'scheduledCount': 11,
            'completedCount': 9,
            'cancelledCount': 3,
            'totalActivities': 38,
          },
        ],
      };

      final client = MockClient((request) async {
        return http.Response(
          jsonEncode(mockData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = ReportViewModel(client: client);

      await tester.pumpWidget(
        MaterialApp(
          home: ReportView(viewModel: vm),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ReportDateRangeBar), findsOneWidget);
      expect(find.byType(WeeklyActivityGraphCard), findsNothing);
      expect(find.text('Weekly activity'), findsNothing);
      // Verify separate stacked graph cards for each status are rendered
      expect(find.byType(StatusActivityGraphCard), findsNWidgets(4));
      expect(find.text('New Bookings'), findsOneWidget);
      expect(find.text('Scheduled Bookings'), findsOneWidget);
      expect(find.text('Completed Bookings'), findsOneWidget);
      expect(find.text('Cancelled Bookings'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
    });

    testWidgets('StatusActivityGraphCard renders status title, total, dynamic bars, and details', (tester) async {
      final items = [
        const BookingReportGraphItem(
          periodLabel: 'Mon',
          periodDate: '2026-11-02',
          newCount: 20,
          scheduledCount: 10,
          completedCount: 5,
          cancelledCount: 2,
          totalActivities: 37,
        ),
        const BookingReportGraphItem(
          periodLabel: 'Tue',
          periodDate: '2026-11-03',
          newCount: 15,
          scheduledCount: 12,
          completedCount: 8,
          cancelledCount: 1,
          totalActivities: 36,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatusActivityGraphCard(
                statusTitle: 'New Bookings',
                statusColor: const Color(0xFF2563EB),
                statusIcon: Icons.fiber_new_rounded,
                getCount: (item) => item.newCount,
                graphData: items,
              ),
            ),
          ),
        ),
      );

      // Verify header
      expect(find.text('New Bookings'), findsOneWidget);
      // Total 20 + 15 = 35
      expect(find.text('Total: 35'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Tue'), findsOneWidget);

      // Verify selected details (defaults to first day: Mon)
      expect(find.text('Mon (2026-11-02)'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Tap on 'Tue' bar to switch selected day
      await tester.tap(find.text('Tue'));
      await tester.pumpAndSettle();
      expect(find.text('Tue (2026-11-03)'), findsOneWidget);
    });

    testWidgets('StatusActivityGraphCard renders GraphSkeletonLoading when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatusActivityGraphCard(
                statusTitle: 'Scheduled Bookings',
                statusColor: const Color(0xFFD97706),
                statusIcon: Icons.calendar_today_rounded,
                getCount: (item) => item.scheduledCount,
                graphData: const [],
                isLoading: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(GraphSkeletonLoading), findsOneWidget);
    });

    test('ReportViewModel sends dateFrom and dateTo query parameters', () async {
      Uri? capturedUri;
      final mockData = {
        'success': true,
        'data': [],
      };

      final client = MockClient((request) async {
        capturedUri = request.url;
        return http.Response(
          jsonEncode(mockData),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = ReportViewModel(client: client);
      vm.setDateRange(from: '2026-11-01', to: '2026-11-07');
      await vm.fetchGraphReport(force: true);

      expect(capturedUri, isNotNull);
      expect(capturedUri!.queryParameters['dateFrom'], equals('2026-11-01'));
      expect(capturedUri!.queryParameters['dateTo'], equals('2026-11-07'));

      // Clear date range
      vm.clearDateRange();
      await vm.fetchGraphReport(force: true);
      expect(capturedUri!.queryParameters.containsKey('dateFrom'), isFalse);
      expect(capturedUri!.queryParameters.containsKey('dateTo'), isFalse);
    });

    test('ReportViewModel defaultDateFrom and defaultDateTo dynamically default to current month', () {
      final now = DateTime.now();
      final expectedFrom = ReportViewModel.formatIsoDate(DateTime(now.year, now.month, 1));
      final expectedTo = ReportViewModel.formatIsoDate(DateTime(now.year, now.month + 1, 0));

      expect(ReportViewModel.defaultDateFrom, equals(expectedFrom));
      expect(ReportViewModel.defaultDateTo, equals(expectedTo));

      final vm = ReportViewModel();
      expect(vm.dateFrom, equals(expectedFrom));
      expect(vm.dateTo, equals(expectedTo));
    });
  });
}
