import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/widgets/document_preview_upload_page.dart';
import 'package:task_chat/new_booking/widgets/lead_document_upload_card.dart';

void main() {
  group('LeadDocumentUploadCard preview & upload structure', () {
    testWidgets('renders attached documents with Preview button and remove icon', (tester) async {
      String? previewedDoc;
      String? removedDoc;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LeadDocumentUploadCard(
              documents: const ['https://example.com/files/sample_lead_doc.pdf'],
              onPreview: (doc) {
                previewedDoc = doc;
              },
              onRemove: (doc) {
                removedDoc = doc;
              },
            ),
          ),
        ),
      );

      // Verify document name is displayed
      expect(find.text('sample_lead_doc.pdf'), findsOneWidget);

      // Verify Preview button is displayed
      expect(find.text('Preview'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

      // Tap Preview button
      await tester.tap(find.text('Preview'));
      await tester.pump();
      expect(previewedDoc, 'https://example.com/files/sample_lead_doc.pdf');

      // Tap Remove button
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(removedDoc, 'https://example.com/files/sample_lead_doc.pdf');
    });

    testWidgets('default onPreview opens DocumentPreviewUploadPage', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LeadDocumentUploadCard(
              documents: ['https://example.com/files/attached_agreement.pdf'],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // Navigated to DocumentPreviewUploadPage
      expect(find.byType(DocumentPreviewUploadPage), findsOneWidget);
      expect(find.text('Document Preview'), findsOneWidget);
      expect(find.text('attached_agreement.pdf'), findsAtLeastNWidgets(1));
    });
  });
}
