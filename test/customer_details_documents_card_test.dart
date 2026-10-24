import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/customer_details_view.dart';
import 'package:task_chat/customer_details/customer_details_view_model.dart';
import 'package:task_chat/customer_details/widgets/customer_documents_card.dart';

void main() {
  testWidgets('CustomerDocumentsCard renders documents header and item details',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomerDocumentsCard(
            documents: ['/uploads/site_plan.pdf'],
          ),
        ),
      ),
    );

    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('site_plan.pdf'), findsOneWidget);
    expect(find.text('2.4 MB • Updated yesterday'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });

  testWidgets('CustomerDocumentsCard triggers onView when visibility icon or document card is tapped',
      (WidgetTester tester) async {
    String? viewedDoc;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomerDocumentsCard(
            documents: const ['/uploads/proposal.pdf'],
            onView: (doc) => viewedDoc = doc,
          ),
        ),
      ),
    );

    // Tap visibility icon
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pump();
    expect(viewedDoc, '/uploads/proposal.pdf');

    // Reset and tap document row
    viewedDoc = null;
    await tester.tap(find.text('proposal.pdf'));
    await tester.pump();
    expect(viewedDoc, '/uploads/proposal.pdf');
  });

  testWidgets('CustomerDetailsView renders documents as clickable',
      (WidgetTester tester) async {
    const customer = CustomerDetailsModel(
      id: '101',
      name: 'John Doe',
      inquiry: 'Gate inquiry',
      status: 'New',
      phoneNumber: '9876543210',
      addressLine1: 'MG Road',
      addressLine2: 'Kochi',
      documents: ['/uploads/blueprints.pdf'],
    );
    final vm = CustomerDetailsViewModel(customer: customer);

    await tester.pumpWidget(
      MaterialApp(
        home: CustomerDetailsView(
          customer: customer,
          viewModel: vm,
        ),
      ),
    );

    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('blueprints.pdf'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });
}
