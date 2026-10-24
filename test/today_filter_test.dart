import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/today/today_model.dart';
import 'package:task_chat/today/today_view.dart';
import 'package:task_chat/today/today_view_model.dart';
import 'package:task_chat/today/widgets/today_filter_bottom_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async => 'test_token',
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  testWidgets('TodayPage renders search bar and filter button in the same row',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response('{"data": []}', 200,
          headers: {'content-type': 'application/json'});
    });
    final vm = TodayViewModel(client: mockClient);

    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();

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
    expect(find.text('Role'), findsNothing);
    expect(find.text('District ID'), findsNothing);
    expect(find.text('Date Range (DD/MM/YYYY)'), findsOneWidget);
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

  test('formatDateToDayMonthYear formats dates to DD/MM/YYYY correctly', () {
    expect(formatDateToDayMonthYear('2026-10-24'), '24/10/2026');
    expect(formatDateToDayMonthYear('10/24/2026'), '24/10/2026');
    expect(formatDateToDayMonthYear('2026-10-24T07:45:30.000Z'), '24/10/2026');
    expect(formatDateToDayMonthYear('24/10/2026'), '24/10/2026');
    expect(formatDateToDayMonthYear(null), '');
    expect(formatDateToDayMonthYear(''), '');
  });

  testWidgets('TodayPage formats item date to date/month/year (DD/MM/YYYY)', (tester) async {
    const mockApiResponse = '''
    {
      "data": [
        {
          "id": 99,
          "name": "Arun Kumar",
          "mobile": "9876543210",
          "address": "Kochi",
          "notes": "",
          "status": "NEW",
          "stateName": "Kerala",
          "districtName": "Ernakulam",
          "areaName": "Edapally",
          "documents": [],
          "scheduleDate": "10/24/2026",
          "createdAt": "2026-10-21T10:38:24.000Z"
        }
      ]
    }
    ''';
    final mockClient = MockClient((request) async {
      return http.Response(mockApiResponse, 200,
          headers: {'content-type': 'application/json'});
    });
    final vm = TodayViewModel(client: mockClient);

    await tester.pumpWidget(
      MaterialApp(
        home: TodayPage(viewModel: vm),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the date is displayed as 24/10/2026 (date/month/year) rather than 10/24/2026
    expect(find.text('24/10/2026'), findsOneWidget);
    expect(find.text('10/24/2026'), findsNothing);
  });
}
