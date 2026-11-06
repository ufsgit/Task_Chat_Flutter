import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/report_activity/activity/activity_model.dart';
import 'package:task_chat/report_activity/activity/booking_history_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockActivity = ActivityModel.fromJson({
    'id': 1001,
    'booking_id': 1001,
    'booking_name': 'Test Client',
    'status': 'New',
    'schedule_date': '2026-11-05T10:00:00Z',
    'notes': 'Initial enquiry',
    'history_id': 1,
    'action_type': 'New Booking Created',
    'action_by_name': 'Officer 1',
    'created_at': '2026-11-05T10:00:00Z',
  });

  testWidgets('BookingHistoryPage renders title and initial booking card', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      final body = jsonEncode({
        'success': true,
        'data': {
          'history': [
            {
              'history_id': 1,
              'booking_id': 1001,
              'booking_name': 'Test Client',
              'action_type': 'New Booking Created',
              'action_by_name': 'Officer 1',
              'action_by_role_id': 1,
              'new_status_label': 'New',
              'new_status_color_code': '#3b82f6',
              'created_at': '2026-11-05T10:00:00Z',
            }
          ]
        }
      });
      return http.Response(body, 200);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BookingHistoryPage(
          initialBooking: mockActivity,
          client: mockClient,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('History'), findsOneWidget);
    expect(find.text('Test Client'), findsWidgets);
  });

  testWidgets('BookingHistoryPage renders diffs when status or notes change', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      final body = jsonEncode({
        'success': true,
        'data': {
          'history': [
            {
              'history_id': 2,
              'booking_id': 1001,
              'booking_name': 'Test Client',
              'action_type': 'Status Updated',
              'action_by_name': 'Manager 1',
              'action_by_role_id': 2,
              'old_status_label': 'New',
              'new_status_label': 'Completed',
              'old_status_color_code': '#3b82f6',
              'new_status_color_code': '#10b981',
              'staff_note': 'Completed installation',
              'created_at': '2026-11-05T11:00:00Z',
            }
          ]
        }
      });
      return http.Response(body, 200);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BookingHistoryPage(
          initialBooking: mockActivity,
          client: mockClient,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('History'), findsOneWidget);
    expect(find.textContaining('Manager 1'), findsOneWidget);
    expect(find.text('Status Updated'), findsOneWidget);
  });

  testWidgets('BookingHistoryPage handles HTTP failure without crashing', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response('Server Error', 500);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: BookingHistoryPage(
          initialBooking: mockActivity,
          client: mockClient,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Page must remain rendered and healthy
    expect(find.text('History'), findsOneWidget);
  });

  testWidgets(
    'BookingHistoryPage parses data where response data is a direct List and shows full data',
    (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'status': true,
          'data': [
            {
              'history_id': 50,
              'booking_id': 1001,
              'booking_name': 'Test Client',
              'action_type': 'Customer Note Added',
              'action_by_name': 'Officer Priya',
              'customer_note': 'Customer requested evening visit',
              'notes': 'Preferred slot: 5pm to 6pm',
              'new_schedule_date': '2026-11-10T11:00:00Z',
              'location': 'Kochi North',
              'new_status_label': 'Scheduled',
              'created_at': '2026-11-06T09:30:00Z',
            }
          ]
        });
        return http.Response(body, 200);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BookingHistoryPage(
            initialBooking: mockActivity,
            client: mockClient,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('History'), findsOneWidget);
      expect(find.text('Customer Note Added'), findsOneWidget);
      expect(find.textContaining('Officer Priya'), findsWidgets);
      expect(find.text('CUSTOMER NOTE'), findsOneWidget);
      expect(find.text('Customer requested evening visit'), findsOneWidget);
      expect(find.text('NOTES'), findsOneWidget);
      expect(find.text('Preferred slot: 5pm to 6pm'), findsOneWidget);
      expect(find.text('SCHEDULED DATE'), findsOneWidget);
      expect(find.text('10/11/2026'), findsOneWidget);
    },
  );

  testWidgets(
    'BookingHistoryPage preserves full activities from allActivities when API returns only 1 creation item',
    (WidgetTester tester) async {
      final act1 = ActivityModel(
        id: '2001',
        bookingId: 1001,
        title: 'Test Client',
        avatarLetter: 'T',
        avatarBgColor: const Color(0xFFDCFCE7),
        avatarTextColor: const Color(0xFF16A34A),
        date: '06/11/2026',
        statusTag: 'Completed',
        actionType: 'Status Updated',
        actionByName: 'Manager Alex',
        noteText: 'Work finished properly',
      );

      final act2 = ActivityModel(
        id: '2000',
        bookingId: 1001,
        title: 'Test Client',
        avatarLetter: 'T',
        avatarBgColor: const Color(0xFFDCFCE7),
        avatarTextColor: const Color(0xFF16A34A),
        date: '05/11/2026',
        statusTag: 'New',
        actionType: 'New Booking Created',
        actionByName: 'Dealer Bob',
      );

      // The API only returns 1 item ("New Booking Created")
      final mockClient = MockClient((request) async {
        final body = jsonEncode({
          'success': true,
          'data': {
            'booking_id': 1001,
            'history': [
              {
                'history_id': 2000,
                'booking_id': 1001,
                'booking_name': 'Test Client',
                'action_type': 'New Booking Created',
                'action_by_name': 'Dealer Bob',
                'new_status_label': 'New',
                'created_at': '2026-11-05T10:00:00Z',
              }
            ]
          }
        });
        return http.Response(body, 200);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: BookingHistoryPage(
            initialBooking: act1,
            allActivities: [act1, act2],
            client: mockClient,
          ),
        ),
      );

      // Frame 1: Before API returns
      await tester.pump();
      expect(find.text('2 updates'), findsOneWidget);
      expect(find.text('Status Updated'), findsOneWidget);
      expect(find.text('New Booking Created'), findsOneWidget);

      // Frame 2: After API returns with only 1 item
      await tester.pump(const Duration(milliseconds: 100));

      // Must STILL show 2 updates, and NOT collapse to a default value of 1 item!
      expect(find.text('2 updates'), findsOneWidget);
      expect(find.text('Status Updated'), findsOneWidget);
      expect(find.text('New Booking Created'), findsOneWidget);
      expect(find.text('Work finished properly'), findsOneWidget);
    },
  );
}
