import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/customer_details/widgets/customer_documents_card.dart';

void main() {
  testWidgets('CustomerDocumentsCard renders documents header, upload button, and item details',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CustomerDocumentsCard(),
        ),
      ),
    );

    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Door_Design_Specs...'), findsOneWidget);
    expect(find.text('2.4 MB • Updated yesterday'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
  });
}
