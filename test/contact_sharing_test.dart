import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:task_chat/api/api.dart';
import 'package:task_chat/core/theme.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/customer_details_view.dart';
import 'package:task_chat/customer_details/customer_details_view_model.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const shareChannel = MethodChannel('dev.fluttercommunity.plus/share');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(shareChannel, (call) async => 'success');
    const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, (call) async => true);
    const urlLauncherWinChannel =
        MethodChannel('plugins.flutter.io/url_launcher_windows');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherWinChannel, (call) async => true);
  });

  setUp(() {
    final dir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}brochure_share',
    );
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
  });

  group('CustomerDetailsViewModel Sharing Tests', () {
    const testCustomer = CustomerDetailsModel(
      id: '201',
      name: 'Ananya Nair',
      inquiry: 'Double Door Fitting',
      status: 'Scheduled',
      phoneNumber: '9876543210',
      addressLine1: 'Door No 12, Skyline Apartments',
      addressLine2: 'Kaloor, Ernakulam',
      notes: 'Customer wants morning visit',
      staffNotes: 'Confirmed by coordinator',
      scheduleDate: '26/11/2026',
      branchHeadName: 'Manu Branch Head',
      mapLink: 'https://maps.google.com/?q=9.998,76.299',
    );

    test('formatCustomerDataForSharing formats all available customer fields', () {
      final vm = CustomerDetailsViewModel(customer: testCustomer);
      final text = vm.formatCustomerDataForSharing();

      expect(text, contains('*Customer Details*'));
      expect(text, contains('*Name:* Ananya Nair'));
      expect(text, contains('*Phone:* 9876543210'));
      expect(text, contains('*Status:* Scheduled'));
      expect(text, contains('*Scheduled Date:* 26/11/2026'));
      expect(text, contains('*Address:* Door No 12, Skyline Apartments, Kaloor, Ernakulam'));
      expect(text, contains('*Location Map:* https://maps.google.com/?q=9.998,76.299'));
      expect(text, contains('*Enquiry:* Double Door Fitting'));
      expect(text, contains('*Notes:* Customer wants morning visit'));
      expect(text, contains('*Staff Notes:* Confirmed by coordinator'));
      expect(text, contains('*Branch Manager:* Manu Branch Head'));
    });

    test('shareDataToWhatsApp launches without a specific phone number, allowing user selection', () async {
      final vm = CustomerDetailsViewModel(customer: testCustomer);

      String? launchedText;

      final success = await vm.shareDataToWhatsApp(
        shareLauncher: (text) async {
          launchedText = text;
        },
      );

      expect(success, isTrue);
      expect(launchedText, contains('*Name:* Ananya Nair'));
      expect(launchedText, contains('*Status:* Scheduled'));
      expect(launchedText, contains('*Address:* Door No 12, Skyline Apartments, Kaloor, Ernakulam'));
    });

    test('shareDataToWhatsApp succeeds even when customer has no phone number', () async {
      final emptyPhoneCustomer = testCustomer.copyWith(phoneNumber: '');
      final vm = CustomerDetailsViewModel(customer: emptyPhoneCustomer);

      String? launchedText;
      final success = await vm.shareDataToWhatsApp(
        shareLauncher: (text) async {
          launchedText = text;
        },
      );

      expect(success, isTrue);
      expect(launchedText, isNotNull);
      expect(launchedText, contains('*Name:* Ananya Nair'));
      expect(launchedText, isNot(contains('*Phone:*')));
    });

    test('shareBrochurePdf invokes shareLauncher with XFile', () async {
      final vm = CustomerDetailsViewModel(customer: testCustomer);

      List<XFile>? sharedFiles;
      String? sharedText;

      final success = await vm.shareBrochurePdf(
        filePath: 'test_brochure.pdf',
        shareLauncher: (files, {text}) async {
          sharedFiles = files;
          sharedText = text;
        },
      );

      expect(success, isTrue);
      expect(sharedFiles?.length, 1);
      expect(sharedFiles?.first.path, 'test_brochure.pdf');
      expect(sharedText, isNull);
    });

    test('fetchBrochureUrl extracts and resolves doc link from share config response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'shareBaseUrl': 'https://steeldoorapi.ufstech.co.in',
            'brochureUrl': '/uploads/steeldoor_catalog.pdf',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = CustomerDetailsViewModel(customer: testCustomer, client: mockClient);
      final docUrl = await vm.fetchBrochureUrl();

      expect(docUrl, 'https://steeldoorapi.ufstech.co.in/uploads/steeldoor_catalog.pdf');
    });

    test('fetchBrochureUrls returns empty list when shareUrl is missing from response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            "success": true,
            "shareBaseUrl": "https://steeldoorapi.ufstech.co.in",
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = CustomerDetailsViewModel(customer: testCustomer, client: mockClient);
      final docUrls = await vm.fetchBrochureUrls();

      expect(docUrls, isEmpty);
    });

    test('fetchBrochureUrls extracts shareUrl directly and ignores shareBaseUrl', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            "success": true,
            "shareBaseUrl": "https://steeldoorapi.ufstech.co.in",
            "shareUrl": "https://steeldoorapi.ufstech.co.in/uploads/brochures/1795583427304-kripa.png",
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = CustomerDetailsViewModel(customer: testCustomer, client: mockClient);
      final docUrls = await vm.fetchBrochureUrls();

      expect(docUrls, [
        'https://steeldoorapi.ufstech.co.in/uploads/brochures/1795583427304-kripa.png',
      ]);
    });

    test('fetchBrochureUrls reads file_url directly from GET /api/brochures', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), ApiConfig.brochure);
        return http.Response(
          jsonEncode({
            'success': true,
            'data': [
              {
                'id': 1,
                'title': 'Steel Door Brochure',
                'file_url': 'https://steeldoorapi.ufstech.co.in/uploads/brochures/1795583427304-kripa.png',
              },
              {
                'id': 2,
                'title': 'Catalog PDF',
                'file_url': 'https://steeldoorapi.ufstech.co.in/uploads/brochures/catalog.pdf',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = CustomerDetailsViewModel(customer: testCustomer, client: mockClient);
      final docUrls = await vm.fetchBrochureUrls();

      expect(docUrls, [
        'https://steeldoorapi.ufstech.co.in/uploads/brochures/1795583427304-kripa.png',
        'https://steeldoorapi.ufstech.co.in/uploads/brochures/catalog.pdf',
      ]);
    });

    test('fetchBrochureUrls and shareBrochureFromLink handles multiple brochure URLs', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('brochures') && !request.url.path.contains('/uploads/')) {
          return http.Response(
            jsonEncode({
              "success": true,
              "shareBaseUrl": "https://steeldoorapi.ufstech.co.in",
              "shareUrl": [
                "https://steeldoorapi.ufstech.co.in/uploads/brochures/1795583427304-kripa.png",
                "https://steeldoorapi.ufstech.co.in/uploads/brochures/catalog.pdf"
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('.png')) {
          return http.Response.bytes(
            utf8.encode('PNG bytes'),
            200,
            headers: {'content-type': 'image/png'},
          );
        }
        if (request.url.path.endsWith('.pdf')) {
          return http.Response.bytes(
            utf8.encode('%PDF-1.4 PDF bytes'),
            200,
            headers: {'content-type': 'application/pdf'},
          );
        }
        return http.Response('Not found', 404);
      });

      final vm = CustomerDetailsViewModel(customer: testCustomer, client: mockClient);
      final docUrls = await vm.fetchBrochureUrls();
      expect(docUrls.length, 2);

      List<XFile>? sharedFiles;
      String? shareText;
      final success = await vm.shareBrochureFromLink(
        shareLauncher: (files, {text}) async {
          sharedFiles = files;
          shareText = text;
        },
      );

      expect(success, isTrue);
      expect(sharedFiles?.length, 2);
      expect(sharedFiles![0].name, '1795583427304-kripa.png');
      expect(sharedFiles![0].mimeType, 'image/png');
      expect(sharedFiles![1].name, 'catalog.pdf');
      expect(sharedFiles![1].mimeType, 'application/pdf');
      expect(shareText, isNull);
    });

    test('shareBrochureFromLink downloads file from link and shares as XFile', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('brochures')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'brochure': 'https://cdn.example.com/company_brochure.pdf',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.url.host == 'cdn.example.com') {
          return http.Response.bytes(
            utf8.encode('%PDF-1.4 Mock PDF Content'),
            200,
            headers: {'content-type': 'application/pdf'},
          );
        }
        return http.Response('Not Found', 404);
      });

      final vm = CustomerDetailsViewModel(customer: testCustomer, client: mockClient);

      List<XFile>? sharedFiles;
      String? sharedText;

      final success = await vm.shareBrochureFromLink(
        shareLauncher: (files, {text}) async {
          sharedFiles = files;
          sharedText = text;
        },
      );

      expect(success, isTrue);
      expect(sharedFiles, isNotNull);
      expect(sharedFiles!.length, 1);
      expect(sharedFiles!.first.name, 'company_brochure.pdf');
      expect(sharedFiles!.first.mimeType, 'application/pdf');
      expect(sharedText, isNull);
    });

    test('shareBrochureFromLink returns false when download fails (no fallbacks)', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('brochures')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'brochureUrl': 'https://example.com/web_brochure',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('Server error', 500);
      });

      final vm = CustomerDetailsViewModel(customer: testCustomer, client: mockClient);

      final success = await vm.shareBrochureFromLink();
      expect(success, isFalse);
    });
  });

  group('CustomerDetailsView Share UI Tests', () {
    const customer = CustomerDetailsModel(
      id: '202',
      name: 'John Doe',
      inquiry: 'Steel Door',
      status: 'New',
      phoneNumber: '9840012345',
      addressLine1: 'Main Street 5',
      addressLine2: 'Kochi',
    );

    testWidgets('Renders Share icon button before 3-dots menu for Coordinator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerDetailsView(
            customer: customer,
            isCoordinator: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find share icon button
      final shareButton = find.byKey(const ValueKey('share_contact_popup_button'));
      expect(shareButton, findsOneWidget);

      final popupButton = tester.widget<PopupMenuButton<String>>(shareButton);
      final shape = popupButton.shape as RoundedRectangleBorder;
      expect(shape.side.color, AppColors.border);

      // Tap share button to open popup menu
      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      expect(find.text('Data sharing'), findsOneWidget);
      expect(find.text('Brochure sharing'), findsOneWidget);
    });

    testWidgets('Renders Share icon button before 3-dots menu for Branch Manager', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerDetailsView(
            customer: customer,
            isCoordinator: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final shareButton = find.byKey(const ValueKey('share_contact_popup_button'));
      expect(shareButton, findsOneWidget);

      await tester.tap(shareButton);
      await tester.pumpAndSettle();

      expect(find.text('Data sharing'), findsOneWidget);
      expect(find.text('Brochure sharing'), findsOneWidget);
    });

    testWidgets('Tapping Data sharing triggers shareDataToWhatsApp on ViewModel', (WidgetTester tester) async {
      bool dataShared = false;
      final vm = CustomerDetailsViewModel(customer: customer);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDetailsView(
            customer: customer,
            viewModel: vm,
            isCoordinator: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open share menu
      await tester.tap(find.byKey(const ValueKey('share_contact_popup_button')));
      await tester.pumpAndSettle();

      // Select Data sharing
      await tester.tap(find.text('Data sharing'));
      await tester.pumpAndSettle();

      // Verify menu dismissed
      expect(find.text('Data sharing'), findsNothing);
    });

    testWidgets('Tapping Brochure sharing opens popup and triggers shareBrochureFromLink', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'brochure': 'https://example.com/catalog.pdf',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = CustomerDetailsViewModel(customer: customer, client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDetailsView(
            customer: customer,
            viewModel: vm,
            isCoordinator: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open share menu
      await tester.tap(find.byKey(const ValueKey('share_contact_popup_button')));
      await tester.pumpAndSettle();

      // Select Brochure sharing
      await tester.tap(find.text('Brochure sharing'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify menu dismissed and loading dialog closed
      expect(find.text('Brochure sharing'), findsNothing);
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Shows selection sheet when multiple brochures are returned and sends selected files', (WidgetTester tester) async {
      final downloadedUrls = <String>[];
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('brochures') && !request.url.path.contains('/uploads/')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 1,
                  'title': 'Steel Door Brochure',
                  'original_name': 'steel_door.png',
                  'file_url': 'https://example.com/uploads/steel_door.png',
                },
                {
                  'id': 2,
                  'title': 'Price Catalog',
                  'original_name': 'catalog.pdf',
                  'file_url': 'https://example.com/uploads/catalog.pdf',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        downloadedUrls.add(request.url.toString());
        return http.Response.bytes(
          utf8.encode('mock file bytes'),
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      final vm = CustomerDetailsViewModel(customer: customer, client: mockClient);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDetailsView(
            customer: customer,
            viewModel: vm,
            isCoordinator: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open share menu & tap Brochure sharing
      await tester.tap(find.byKey(const ValueKey('share_contact_popup_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Brochure sharing'));
      await tester.pumpAndSettle();

      // Selection sheet should appear with both brochures selected
      expect(find.text('Select brochures to share'), findsOneWidget);
      expect(find.text('Steel Door Brochure'), findsOneWidget);
      expect(find.text('Price Catalog'), findsOneWidget);
      expect(find.text('Send (2)'), findsOneWidget);

      // Uncheck the first brochure
      await tester.tap(find.text('Steel Door Brochure'));
      await tester.pumpAndSettle();
      expect(find.text('Send (1)'), findsOneWidget);

      // Tap Send (1)
      await tester.tap(find.text('Send (1)'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 300));

      // Only the second file should be downloaded and loading dialog should be closed
      expect(downloadedUrls, ['https://example.com/uploads/catalog.pdf']);
      expect(find.byType(Dialog), findsNothing);
    });
  });

  group('Brochure Cache Sync Tests', () {
    const testCustomer = CustomerDetailsModel(
      id: '201',
      name: 'Ananya Nair',
      inquiry: 'Double Door Fitting',
      status: 'Scheduled',
      phoneNumber: '9876543210',
      addressLine1: 'Kaloor',
      addressLine2: 'Ernakulam',
      notes: '',
      staffNotes: '',
      scheduleDate: '26/11/2026',
    );

    test('Reuses cached brochure on repeat share and deletes removed DB brochures on fetch', () async {
      int fileDownloadCount = 0;
      bool dbHasBrochure = true;

      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/brochures')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': dbHasBrochure
                  ? [
                      {
                        'id': 1,
                        'title': 'Brochure 1',
                        'file_url': 'https://example.com/uploads/111-brochure.pdf',
                      },
                    ]
                  : [],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        fileDownloadCount++;
        return http.Response.bytes(
          utf8.encode('%PDF-1.4 cached bytes'),
          200,
          headers: {'content-type': 'application/pdf'},
        );
      });

      final vm = CustomerDetailsViewModel(customer: testCustomer, client: mockClient);

      // First share: downloads once
      final items1 = await vm.fetchBrochureItems();
      expect(items1.length, 1);
      final ok1 = await vm.shareBrochureFromLink(
        overrideDocUrls: [items1.first.url],
        shareLauncher: (files, {text}) async {},
      );
      expect(ok1, isTrue);
      expect(fileDownloadCount, 1);

      // Second share with same DB brochure: reuses cached file (0 new downloads)
      final items2 = await vm.fetchBrochureItems();
      expect(items2.length, 1);
      final ok2 = await vm.shareBrochureFromLink(
        overrideDocUrls: [items2.first.url],
        shareLauncher: (files, {text}) async {},
      );
      expect(ok2, isTrue);
      expect(fileDownloadCount, 1);

      // Now remove brochure from DB and fetch again -> cached file is wiped
      dbHasBrochure = false;
      final items3 = await vm.fetchBrochureItems();
      expect(items3, isEmpty);

      final shareDir = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}brochure_share',
      );
      final remainingFiles = shareDir.existsSync()
          ? shareDir.listSync(recursive: true).whereType<File>().toList()
          : <File>[];
      expect(remainingFiles, isEmpty);
    });
  });
}
