import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/login_page/token_storage.dart';
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
}
