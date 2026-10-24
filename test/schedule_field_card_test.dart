import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/update_status/widgets/calender_field_card.dart';

void main() {
  testWidgets('ScheduleFieldCard allows selecting year from dropdown menu', (tester) async {
    String? selectedDate;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ScheduleFieldCard(
              dateText: '10/24/2024',
              onDateChanged: (val) => selectedDate = val,
            ),
          ),
        ),
      ),
    );

    // Expand the calendar card by tapping the date container
    await tester.tap(find.text('10/24/2024'));
    await tester.pumpAndSettle();

    // Verify current month and year button
    expect(find.text('October'), findsOneWidget);
    expect(find.widgetWithText(PopupMenuButton<int>, '2024'), findsOneWidget);

    // Tap on the Year dropdown button to open year list
    final yearButton = find.widgetWithText(PopupMenuButton<int>, '2024');
    await tester.tap(yearButton);
    await tester.pumpAndSettle();

    // Select 2026 from the dropdown list
    final year2026Item = find.text('2026').last;
    expect(year2026Item, findsOneWidget);
    await tester.tap(year2026Item);
    await tester.pumpAndSettle();

    // Verify calendar updated to 2026
    expect(find.widgetWithText(PopupMenuButton<int>, '2026'), findsOneWidget);

    // Tap 'Set Date' to confirm
    await tester.tap(find.text('Set Date'));
    await tester.pumpAndSettle();

    expect(selectedDate, '10/24/2026');
  });
}
