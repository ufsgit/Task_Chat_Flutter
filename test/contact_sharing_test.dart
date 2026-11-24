import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/customer_details_view.dart';
import 'package:task_chat/customer_details/customer_details_view_model.dart';

void main() {
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

    test('shareDataToWhatsApp sends formatted text to customer phone number', () async {
      final vm = CustomerDetailsViewModel(customer: testCustomer);

      String? launchedPhone;
      String? launchedText;

      final success = await vm.shareDataToWhatsApp(
        whatsAppLauncher: (phone, {text}) async {
          launchedPhone = phone;
          launchedText = text;
        },
      );

      expect(success, isTrue);
      expect(launchedPhone, '9876543210');
      expect(launchedText, contains('*Name:* Ananya Nair'));
      expect(launchedText, contains('*Status:* Scheduled'));
    });

    test('shareDataToWhatsApp returns false if phone is empty', () async {
      final emptyPhoneCustomer = testCustomer.copyWith(phoneNumber: '');
      final vm = CustomerDetailsViewModel(customer: emptyPhoneCustomer);

      bool called = false;
      final success = await vm.shareDataToWhatsApp(
        whatsAppLauncher: (phone, {text}) async {
          called = true;
        },
      );

      expect(success, isFalse);
      expect(called, isFalse);
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
      expect(sharedText, contains('Ananya Nair'));
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
  });
}
