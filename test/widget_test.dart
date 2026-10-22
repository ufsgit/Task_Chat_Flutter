// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:task_chat/login_page/login_view.dart';
import 'package:task_chat/login_page/token_storage.dart';
import 'package:task_chat/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TokenStorage.useMemoryOnly = true;
  });

  tearDown(() {
    TokenStorage.useMemoryOnly = false;
  });

  testWidgets('FitmateApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const FitmateApp());

    // Initially shows SplashScreen with brand title
    expect(find.text('Fitmate'), findsOneWidget);

    // After 2-second splash screen completes, transitions to LoginPage
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
