import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_chat/core/widgets/pulsing_dot_loader.dart';
import 'package:task_chat/login_page/login_view.dart';
import 'package:task_chat/login_page/token_storage.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TokenStorage.useMemoryOnly = true;
  });

  tearDown(() {
    TokenStorage.useMemoryOnly = false;
  });

  testWidgets('PulsingDotLoader renders correct number of dots and animates', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: PulsingDotLoader(
              count: 3,
              color: Colors.white,
              size: 8.0,
            ),
          ),
        ),
      ),
    );

    // Verify PulsingDotLoader exists
    expect(find.byType(PulsingDotLoader), findsOneWidget);

    // Verify exactly 3 dots (Transform / Opacity) inside PulsingDotLoader
    final loaderFinder = find.byType(PulsingDotLoader);
    final dotTransforms = find.descendant(
      of: loaderFinder,
      matching: find.byType(Transform),
    );
    expect(dotTransforms, findsNWidgets(3));

    final dotOpacities = find.descendant(
      of: loaderFinder,
      matching: find.byType(Opacity),
    );
    expect(dotOpacities, findsNWidgets(3));

    // Advance animation by 300ms
    await tester.pump(const Duration(milliseconds: 300));
    expect(dotTransforms, findsNWidgets(3));
  });

  testWidgets('LoginPage displays PulsingDotLoader when loading instead of CircularProgressIndicator', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    // Initially shows Log In text
    expect(find.text('Log In'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(PulsingDotLoader), findsNothing);
  });
}
