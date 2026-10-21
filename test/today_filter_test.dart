import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/today/today_view.dart';
import 'package:task_chat/today/widgets/today_filter_bottom_sheet.dart';

void main() {
  testWidgets('TodayPage renders search bar and filter button in the same row',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayPage(),
      ),
    );

    // Verify search bar and filter icon exist
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byIcon(Icons.tune_rounded), findsOneWidget);

    // Tap filter button to open bottom sheet
    await tester.tap(find.byIcon(Icons.tune_rounded));
    await tester.pumpAndSettle();

    // Verify filter options bottom sheet opened
    expect(find.text('Filter by Status'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Location'), findsNothing);
    expect(find.text('Apply Filter'), findsOneWidget);

    // Select 'Completed' status inside bottom sheet and apply
    await tester.tap(
      find.descendant(
        of: find.byType(TodayFilterBottomSheet),
        matching: find.text('Completed'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply Filter'));
    await tester.pumpAndSettle();

    // Bottom sheet is closed and active filter badge is displayed
    expect(find.text('Filter by Status'), findsNothing);
    expect(find.text('Status: Completed'), findsOneWidget);
  });
}
