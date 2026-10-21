import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/widgets/contact_actions_card.dart';
import 'package:task_chat/customer_details/widgets/customer_header_card.dart';

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

  testWidgets('CustomerHeaderCard displays status badge next to customer name', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomerHeaderCard(customer: customer),
        ),
      ),
    );

    // Verify name and status exist
    expect(find.text('Syam'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);

    // Both should be in a Row
    final nameFinder = find.text('Syam');
    final rowAncestor = find.ancestor(
      of: nameFinder,
      matching: find.byType(Row),
    );
    expect(rowAncestor, findsOneWidget);
  });

  testWidgets(
    'ContactActionsCard orders sections: Address first, Notes second, Contact last',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ContactActionsCard(customer: customer),
          ),
        ),
      );

      // Verify all sections exist
      final addressFinder = find.text('MG Road, Allepy');
      final notesFinder = find.text('Notes & Interaction History');
      final phoneFinder = find.text('+91 9876543210');

      expect(addressFinder, findsOneWidget);
      expect(notesFinder, findsOneWidget);
      expect(phoneFinder, findsOneWidget);

      // Verify vertical ordering: Address Y < Notes Y < Phone Y
      final addressY = tester.getTopLeft(addressFinder).dy;
      final notesY = tester.getTopLeft(notesFinder).dy;
      final phoneY = tester.getTopLeft(phoneFinder).dy;

      expect(addressY < notesY, isTrue, reason: 'Address must appear before Notes');
      expect(notesY < phoneY, isTrue, reason: 'Notes must appear before Contact (Phone)');
    },
  );

  testWidgets('Notes box in ContactActionsCard is clickable and typable', (
    WidgetTester tester,
  ) async {
    const emptyCustomer = CustomerDetailsData(
      id: '2',
      name: 'Devika',
      inquiry: 'Door Inquiry',
      status: 'Completed',
      phoneNumber: '9845123490',
      addressLine1: 'Civil Line Road',
      addressLine2: 'Thrissur',
      notes: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ContactActionsCard(customer: emptyCustomer),
        ),
      ),
    );

    // Verify hint text when empty
    expect(find.text('Add notes here...'), findsOneWidget);

    // Tap and type in notes field
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Client called regarding measurements');
    await tester.pumpAndSettle();

    // Verify entered text is displayed
    expect(find.text('Client called regarding measurements'), findsOneWidget);
  });
}
