import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/connectivity_service.dart';
import 'package:task_chat/core/widgets/global_connectivity_banner.dart';

void main() {
  setUp(() {
    ConnectivityService.isTestEnvironment = true;
    ConnectivityService.instance.setConnected(true);
  });

  tearDown(() {
    ConnectivityService.instance.setConnected(true);
  });

  testWidgets('GlobalConnectivityBanner does not display banner when connected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlobalConnectivityBanner(
          child: Scaffold(
            body: Center(child: Text('Main Screen Content')),
          ),
        ),
      ),
    );

    expect(find.text('Main Screen Content'), findsOneWidget);
    expect(find.text('No Internet Connection'), findsNothing);
  });

  testWidgets('GlobalConnectivityBanner shows banner when disconnected and hides when reconnected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlobalConnectivityBanner(
          child: Scaffold(
            body: Center(child: Text('Main Screen Content')),
          ),
        ),
      ),
    );

    expect(find.text('No Internet Connection'), findsNothing);

    // Simulate API call failure due to no internet
    ConnectivityService.instance.reportFailure();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No Internet Connection'), findsOneWidget);
    expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    // Simulate internet restoration (DNS check or successful API response)
    ConnectivityService.instance.reportSuccess();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Shows "Back Online" briefly
    expect(find.text('Back Online'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

    // After 2.5s timer expires, banner disappears
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Back Online'), findsNothing);
  });

  testWidgets('GlobalConnectivityBanner allows user to close/dismiss no internet popup', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlobalConnectivityBanner(
          child: Scaffold(
            body: Center(child: Text('Main Screen Content')),
          ),
        ),
      ),
    );

    // Trigger failure
    ConnectivityService.instance.reportFailure();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No Internet Connection'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);

    // Tap Close button
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    // Verify popup is dismissed
    expect(find.text('No Internet Connection'), findsNothing);
    expect(find.text('Main Screen Content'), findsOneWidget);
  });

  testWidgets('GlobalConnectivityBanner renders cleanly inside MaterialApp.builder without overlay errors', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => GlobalConnectivityBanner(
          child: child ?? const SizedBox.shrink(),
        ),
        home: const Scaffold(
          body: Center(child: Text('App Screen')),
        ),
      ),
    );

    // Simulate failure
    ConnectivityService.instance.reportFailure();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No Internet Connection'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Tap the 'X' close icon
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(find.text('No Internet Connection'), findsNothing);
    expect(find.text('App Screen'), findsOneWidget);
  });
}
