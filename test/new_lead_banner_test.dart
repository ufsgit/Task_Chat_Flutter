import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/widgets/new_lead_in_app_banner.dart';
import 'package:task_chat/services/new_lead_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    NewLeadService.instance.dismiss();
  });

  tearDown(() {
    NewLeadService.instance.dismiss();
  });

  testWidgets('NewLeadBannerOverlay is hidden initially', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(child: Text('Main Content')),
              NewLeadBannerOverlay(),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Main Content'), findsOneWidget);
    expect(find.text('New Lead Added'), findsNothing);
  });

  testWidgets('NewLeadBannerOverlay displays when notifyNewLead is called', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(child: Text('Main Content')),
              NewLeadBannerOverlay(),
            ],
          ),
        ),
      ),
    );

    NewLeadService.instance.notifyNewLead(
      leadName: 'Rohan Sharma',
      location: 'Kochi',
      autoRefresh: false,
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('New Lead Added'), findsOneWidget);
    expect(find.text('NEW'), findsOneWidget);
    expect(find.text('Rohan Sharma • Kochi'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);
  });

  testWidgets('Tapping Refresh triggers callback and dismisses the banner', (tester) async {
    bool refreshCalled = false;
    NewLeadService.instance.addRefreshListener(() {
      refreshCalled = true;
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(child: Text('Main Content')),
              NewLeadBannerOverlay(),
            ],
          ),
        ),
      ),
    );

    NewLeadService.instance.notifyNewLead(
      leadName: 'Anoop Kumar',
      autoRefresh: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('New Lead Added'), findsOneWidget);
    expect(find.text('Refresh'), findsOneWidget);

    // Tap Refresh button
    await tester.tap(find.text('Refresh'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(refreshCalled, isTrue);
    expect(find.text('New Lead Added'), findsNothing);
  });

  testWidgets('Tapping close icon dismisses banner without triggering refresh', (tester) async {
    bool refreshCalled = false;
    NewLeadService.instance.addRefreshListener(() {
      refreshCalled = true;
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(child: Text('Main Content')),
              NewLeadBannerOverlay(),
            ],
          ),
        ),
      ),
    );

    NewLeadService.instance.notifyNewLead(
      leadName: 'Priya Nair',
      autoRefresh: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('New Lead Added'), findsOneWidget);

    // Tap close icon
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('New Lead Added'), findsNothing);
    expect(refreshCalled, isFalse);
  });

  testWidgets('Banner auto-dismisses after duration', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(child: Text('Main Content')),
              NewLeadBannerOverlay(
                autoDismissDuration: Duration(seconds: 2),
              ),
            ],
          ),
        ),
      ),
    );

    NewLeadService.instance.notifyNewLead(
      leadName: 'Sanjay Dutt',
      autoRefresh: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('New Lead Added'), findsOneWidget);

    // Fast-forward past autoDismissDuration
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('New Lead Added'), findsNothing);
  });
}

