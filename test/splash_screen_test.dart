import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_chat/login_page/login_view.dart';
import 'package:task_chat/login_page/token_storage.dart';
import 'package:task_chat/splash/splash_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TokenStorage.useMemoryOnly = true;
  });

  tearDown(() {
    TokenStorage.useMemoryOnly = false;
  });

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

  testWidgets('SplashScreen routes directly to HomePage when session token exists',
      (WidgetTester tester) async {
    final tokenStorage = TokenStorage();
    await tokenStorage.savetoken('test_active_session_token');

    await tester.pumpWidget(
      MaterialApp(
        home: SplashScreen(
          tokenStorage: tokenStorage,
          homeBuilder: (_, user) => const Scaffold(
            body: Text('Home Screen Loaded'),
          ),
        ),
      ),
    );

    // Initial frame on SplashScreen
    expect(find.byType(SplashScreen), findsOneWidget);

    // Advance past the 1-second splash delay and session check
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Transitioned to HomePage / custom homeBuilder
    expect(find.text('Home Screen Loaded'), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);

    // Cleanup
    await tokenStorage.deleteToken();
  });
}
