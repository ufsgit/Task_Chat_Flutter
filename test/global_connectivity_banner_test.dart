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
}
