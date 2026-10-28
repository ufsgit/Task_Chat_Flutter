import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/customer_details_view.dart';
import 'package:task_chat/customer_details/customer_details_view_model.dart';
import 'package:task_chat/customer_details/widgets/customer_documents_card.dart';
import 'package:task_chat/customer_details/widgets/customer_header_card.dart';
import 'package:task_chat/customer_details/widgets/update_status_button.dart';

void main() {
  const customer = CustomerDetailsData(
    id: '1',
    name: 'Syam',
    inquiry: 'Fitmate Inquiry',
    status: 'Scheduled',
    phoneNumber: '+91 9876543210',
    addressLine1: 'MG Road, Allepy',
    addressLine2: 'Kerala, 688001',
    notes: 'Interested in annual membership.',
    hasBeenScheduled: true,
  );

  testWidgets(
    'CustomerHeaderCard contains Name, Address, Phone, Status, Note in specified vertical order',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: CustomerHeaderCard(customer: customer),
            ),
          ),
        ),
      );

      // 1. Name
      final nameFinder = find.text('Syam');
      expect(nameFinder, findsOneWidget);

      // 2. Address
      final addressFinder = find.text('MG Road, Allepy');
      expect(addressFinder, findsOneWidget);

      // 3. Phone number
      final phoneFinder = find.text('+91 9876543210');
      expect(phoneFinder, findsOneWidget);

      // 4. Status
      final statusHeaderFinder = find.text('STATUS');
      expect(statusHeaderFinder, findsOneWidget);
      final statusBadgeFinder = find.text('Scheduled');
      expect(statusBadgeFinder, findsOneWidget);

      // 5. Note
      final notesHeaderFinder = find.text('NOTES');
      expect(notesHeaderFinder, findsOneWidget);
      final noteContentFinder = find.text('Interested in annual membership.');
      expect(noteContentFinder, findsOneWidget);

      // Verify strict vertical ordering: Name < Address < Phone < Status < Note
      final nameY = tester.getTopLeft(nameFinder).dy;
      final addressY = tester.getTopLeft(addressFinder).dy;
      final phoneY = tester.getTopLeft(phoneFinder).dy;
      final statusY = tester.getTopLeft(statusHeaderFinder).dy;
      final noteY = tester.getTopLeft(notesHeaderFinder).dy;

      expect(nameY < addressY, isTrue, reason: 'Name must appear before Address');
      expect(addressY < phoneY, isTrue, reason: 'Address must appear before Phone');
      expect(phoneY < statusY, isTrue, reason: 'Phone must appear before Status');
      expect(statusY < noteY, isTrue, reason: 'Status must appear before Note');
    },
  );

  testWidgets(
    'CustomerDetailsView orders page as: 1 Contact Info Section, then Update Status, then Documents',
    (WidgetTester tester) async {
      final vm = CustomerDetailsViewModel(customer: customer);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDetailsView(
            customer: customer,
            viewModel: vm,
          ),
        ),
      );

      final contactSectionFinder = find.byType(CustomerHeaderCard);
      final updateStatusFinder = find.byType(UpdateStatusButton);
      final documentsCardFinder = find.byType(CustomerDocumentsCard);

      expect(contactSectionFinder, findsOneWidget);
      expect(updateStatusFinder, findsOneWidget);
      expect(documentsCardFinder, findsOneWidget);

      final contactY = tester.getTopLeft(contactSectionFinder).dy;
      final updateY = tester.getTopLeft(updateStatusFinder).dy;
      final docY = tester.getTopLeft(documentsCardFinder).dy;

      expect(
        contactY < updateY,
        isTrue,
        reason: 'Contact Info section must appear before Update Status button',
      );
      expect(
        updateY < docY,
        isTrue,
        reason: 'Update Status button must appear before Documents card',
      );
    },
  );
}
