import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/widgets/circular_back_button.dart';
import 'package:task_chat/customer_details/customer_details_view.dart';
import 'package:task_chat/notification_page/notification_page.dart';
import 'package:task_chat/notification_page/widgets/notification_item_tile.dart';

void main() {
  testWidgets('NotificationPage renders header, filters, sections, and items correctly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: NotificationPage(showBottomBar: false),
      ),
    );

    // Verify AppBar
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.byType(CircularBackButton), findsOneWidget);

    // Verify Filter Chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);

    // Verify Section Headers
    expect(find.text('TODAY'), findsOneWidget);
    expect(find.text('THIS WEEK'), findsOneWidget);
    expect(find.text('EARLIER'), findsOneWidget);

    // Verify Notification Items in "All" view
    expect(find.text('Ramesh Kumar'), findsOneWidget);
    expect(find.text('Manoj jayan'), findsOneWidget);
    expect(find.text('Sunita devi'), findsOneWidget);
    expect(find.text('kochi'), findsOneWidget);
    expect(find.text('10m ago'), findsOneWidget);

    // Verify red urgency indicator exists on Sunita devi
    final tiles = tester.widgetList<NotificationItemTile>(find.byType(NotificationItemTile));
    final sunitaTile = tiles.firstWhere((tile) => tile.item.name == 'Sunita devi');
    expect(sunitaTile.item.hasRedIndicator, isTrue);

    // Tap "Pending" filter
    await tester.tap(find.text('Pending'));
    await tester.pumpAndSettle();

    // Ramesh Kumar should now be filtered out
    expect(find.text('Ramesh Kumar'), findsNothing);
    // Sunita devi is pending, so still visible
    expect(find.text('Sunita devi'), findsOneWidget);

    // Switch back to "All"
    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.text('Ramesh Kumar'), findsOneWidget);

    // Tap on Ramesh Kumar item to navigate to CustomerDetailsPage
    await tester.tap(find.text('Ramesh Kumar'));
    await tester.pumpAndSettle();

    expect(find.byType(CustomerDetailsPage), findsOneWidget);
  });
}
