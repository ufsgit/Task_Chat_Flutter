import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/update_status/update_status_data.dart';
import 'package:task_chat/update_status/update_status_page.dart';

void main() {
  test('UpdateStatusVisibility hides schedule when cancelled', () {
    const scheduledVis = UpdateStatusVisibility('Scheduled');
    expect(scheduledVis.showSchedule, isTrue);

    const completedVis = UpdateStatusVisibility('Completed');
    expect(completedVis.showSchedule, isTrue);

    const cancelledVis = UpdateStatusVisibility('Cancelled');
    expect(cancelledVis.showSchedule, isFalse);
  });

  testWidgets('UpdateStatusPage hides Schedule card when Cancelled is selected', (
    WidgetTester tester,
  ) async {
    const customer = CustomerDetailsData(
      id: '1',
      name: 'Test Customer',
      inquiry: 'Fitmate Inquiry',
      status: 'Scheduled',
      phoneNumber: '+91 9876543210',
      addressLine1: 'Kochi',
      addressLine2: 'Kerala',
      notes: '',
      hasBeenScheduled: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: UpdateStatusPage(customer: customer),
      ),
    );
    await tester.pumpAndSettle();

    // Initially 'Scheduled' is selected, so 'Schedule' text and calendar card should be visible
    expect(find.text('Schedule'), findsOneWidget);

    // Tap 'Cancelled' chip
    await tester.tap(find.text('Cancelled'));
    await tester.pumpAndSettle();

    // Now 'Schedule' should be hidden
    expect(find.text('Schedule'), findsNothing);

    // Tap 'Scheduled' chip again
    await tester.tap(find.text('Scheduled'));
    await tester.pumpAndSettle();

    // 'Schedule' should reappear
    expect(find.text('Schedule'), findsOneWidget);
  });
}
