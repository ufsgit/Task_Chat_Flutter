import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/settings/settings_page.dart';
import 'package:task_chat/today/today_page.dart';

void main() {
  testWidgets('SettingsPage renders initials RS, user info, About, and Logout',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SettingsPage(),
        ),
      ),
    );

    expect(find.text('RS'), findsOneWidget);
    expect(find.text('Rajesh Sharma'), findsOneWidget);
    expect(find.text('+91 98765 43210'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Block contacts, task visibility, status'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('TodayPage switches to Settings tab on bottom nav tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TodayPage(),
      ),
    );

    // Initially Dashboard or Today is shown
    expect(find.text('RS'), findsNothing);

    // Tap on Settings nav item icon
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Verify SettingsPage content is visible
    expect(find.text('RS'), findsOneWidget);
    expect(find.text('Rajesh Sharma'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });
}
