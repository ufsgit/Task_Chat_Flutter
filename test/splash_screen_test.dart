import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/login_page/login_view.dart';
import 'package:task_chat/splash/splash_screen.dart';

void main() {
  testWidgets('SplashScreen displays brand elements and navigates to LoginPage after 1 second',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    // Initial frame: brand name should be present
    expect(find.text('Fitmate'), findsOneWidget);

    // Advance 500ms - still on SplashScreen
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);

    // Advance past the 1-second mark and transition animation
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Now transitioned to LoginPage
    expect(find.byType(LoginPage), findsOneWidget);
  });
}
