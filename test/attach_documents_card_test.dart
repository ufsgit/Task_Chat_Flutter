import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/update_status/widgets/attach_documents_card.dart';

void main() {
  testWidgets('AttachDocumentsCard renders section header, 1 file attached badge, and preview/delete actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AttachDocumentsCard(),
        ),
      ),
    );

    expect(find.text('Attach Documents'), findsOneWidget);
    expect(find.text('1 file attached'), findsOneWidget);
    expect(find.text('Door_Measurement...'), findsOneWidget);
    expect(find.text('PDF • 2.4 MB'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
  });
}
