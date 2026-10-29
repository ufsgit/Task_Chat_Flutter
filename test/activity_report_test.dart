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

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActivityView(
                viewModel: ActivityViewModel(
                  client: MockClient((_) async => http.Response('{}', 200)),
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

        expect(find.text('STATUS'), findsNWidgets(2));
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
}
