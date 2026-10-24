import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/update_status/widgets/attach_documents_card.dart';

void main() {
  testWidgets('AttachDocumentsCard renders section header and preview/delete actions',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AttachDocumentsCard(),
        ),
      ),
    );

    expect(find.text('Documents'), findsOneWidget);
    expect(find.text('Door_Measurement...'), findsOneWidget);
    expect(find.text('PDF • 2.4 MB'), findsOneWidget);
    expect(find.text('Preview'), findsOneWidget);
    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.description_outlined), findsOneWidget);
  });

  testWidgets('AttachDocumentsCard only renders Add Document button for upload',
      (WidgetTester tester) async {
    bool attached = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AttachDocumentsCard(
            documents: const [],
            onAttach: () => attached = true,
          ),
        ),
      ),
    );

    // Only Add Document button is shown for upload, not "Upload"
    expect(find.text('Add Document'), findsOneWidget);
    expect(find.text('Upload'), findsNothing);

    await tester.tap(find.text('Add Document'));
    await tester.pump();
    expect(attached, isTrue);
  });
}
