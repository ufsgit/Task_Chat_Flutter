import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/widgets/app_pill_notification.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/widgets/customer_header_card.dart';
import 'package:task_chat/today/today_model.dart';
import 'package:task_chat/update_status/branch_manager/branch_manager_update_status_logic.dart';
import 'package:task_chat/update_status/coordinators/coordinator_update_status_logic.dart';

void main() {
  group('Must Fix 1 & 2: Call and WhatsApp on empty phone show error banner, no fake data', () {
    testWidgets('Tapping Call with empty phone number displays error notification banner', (WidgetTester tester) async {
      const customer = CustomerDetailsModel(
        id: '10',
        name: 'Empty Phone Contact',
        inquiry: '',
        status: 'New',
        phoneNumber: '',
        addressLine1: '',
        addressLine2: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomerHeaderCard(customer: customer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No phone number'), findsOneWidget);
      expect(find.text('No address provided'), findsOneWidget);

      // Tap Call button
      await tester.tap(find.text('Call'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No phone number available for this contact'), findsOneWidget);
    });

    testWidgets('Tapping WhatsApp with empty phone number displays error notification banner', (WidgetTester tester) async {
      const customer = CustomerDetailsModel(
        id: '11',
        name: 'Empty Phone Contact',
        inquiry: '',
        status: 'New',
        phoneNumber: '',
        addressLine1: '',
        addressLine2: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomerHeaderCard(customer: customer),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap WhatsApp button
      await tester.tap(find.text('WhatsApp'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('No phone number available for this contact'), findsOneWidget);
    });

    test('CustomerDetailsModel does not inject Springfield or 742 Evergreen or 7096797345', () {
      final booking = BookingModel(
        id: 123,
        name: 'Real User',
        mobile: '',
        address: '',
        notes: '',
        status: 'New',
        stateName: '',
        districtName: '',
        areaName: '',
        documents: [],
      );

      final customer = CustomerDetailsModel.fromBooking(booking);
      expect(customer.phoneNumber, isEmpty);
      expect(customer.addressLine1, isEmpty);
      expect(customer.addressLine2, isEmpty);
      expect(customer.inquiry, isEmpty);

      final customerFromChat = CustomerDetailsModel.fromChatInfo(name: 'Chat Lead');
      expect(customerFromChat.phoneNumber, isEmpty);
      expect(customerFromChat.addressLine1, isEmpty);
      expect(customerFromChat.addressLine2, isEmpty);
      expect(customerFromChat.inquiry, isEmpty);
    });
  });

  group('Must Fix 3: Non-numeric customer ID fails safely and never defaults to ID 1', () {
    test('CoordinatorUpdateStatusLogic rejects non-numeric or <= 0 customer ID', () async {
      final logic = CoordinatorUpdateStatusLogic();
      const invalidCustomer = CustomerDetailsModel(
        id: 'booking_alpha_invalid',
        name: 'Invalid Lead',
        inquiry: '',
        status: 'Scheduled',
        phoneNumber: '9876543210',
        addressLine1: '',
        addressLine2: '',
      );

      final result = await logic.submitStatusUpdate(
        customer: invalidCustomer,
        status: 'Scheduled',
        scheduleDate: '26/11/2026',
        notes: 'Test',
        branchManager: 'BM',
      );

      expect(result, isFalse);
    });

    test('BranchManagerUpdateStatusLogic rejects non-numeric or <= 0 customer ID', () async {
      final logic = BranchManagerUpdateStatusLogic();
      const invalidCustomer = CustomerDetailsModel(
        id: 'not_a_number',
        name: 'Invalid Lead',
        inquiry: '',
        status: 'Scheduled',
        phoneNumber: '9876543210',
        addressLine1: '',
        addressLine2: '',
      );

      final result = await logic.submitStatusUpdate(
        customer: invalidCustomer,
        status: 'Scheduled',
        scheduleDate: '26/11/2026',
        notes: 'Test',
      );

      expect(result, isFalse);
    });
  });

  group('Must Fix 4: Inquiry derived from API or left empty', () {
    test('BookingModel parses inquiry from API or leaves empty', () {
      final withInquiry = BookingModel.fromJson({
        'id': 1,
        'name': 'Test',
        'inquiry': 'Custom Security Door 7ft',
      });
      expect(withInquiry.inquiry, 'Custom Security Door 7ft');

      final customer1 = CustomerDetailsModel.fromBooking(withInquiry);
      expect(customer1.inquiry, 'Custom Security Door 7ft');

      final withoutInquiry = BookingModel.fromJson({
        'id': 2,
        'name': 'Test 2',
      });
      expect(withoutInquiry.inquiry, isNull);

      final customer2 = CustomerDetailsModel.fromBooking(withoutInquiry);
      expect(customer2.inquiry, isEmpty);
    });

    testWidgets('CustomerHeaderCard displays inquiry under customer name when present', (WidgetTester tester) async {
      const customerWithInquiry = CustomerDetailsModel(
        id: '1',
        name: 'Abhiram',
        inquiry: 'Fireproof Double Door',
        status: 'New',
        phoneNumber: '9876543210',
        addressLine1: 'MG Road',
        addressLine2: 'Kochi',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CustomerHeaderCard(customer: customerWithInquiry),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Abhiram'), findsOneWidget);
      expect(find.text('Fireproof Double Door'), findsOneWidget);
    });
  });
}
