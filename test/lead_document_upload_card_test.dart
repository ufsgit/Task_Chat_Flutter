import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/new_booking/add_booking.dart';
import 'package:task_chat/new_booking/widgets/lead_document_upload_card.dart';

void main() {
  testWidgets('LeadDocumentUploadCard displays all elements correctly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LeadDocumentUploadCard(),
        ),
      ),
    );

    expect(find.text('Attach Documents'), findsOneWidget);
    expect(find.text('Max 10MB'), findsOneWidget);
    expect(find.text('Tap to browse or upload file'), findsOneWidget);
    expect(find.text('Supports PDF, DOCX, PNG, or JPG'), findsOneWidget);
  });

  testWidgets('CreateLeadPage displays document upload option', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: add_booking(),
      ),
    );

    expect(find.byType(LeadDocumentUploadCard), findsOneWidget);
    expect(find.text('Attach Documents'), findsOneWidget);
    expect(find.text('Max 10MB'), findsOneWidget);
    expect(find.text('Tap to browse or upload file'), findsOneWidget);
    expect(find.text('Supports PDF, DOCX, PNG, or JPG'), findsOneWidget);
  });

  testWidgets('LeadDocumentUploadCard renders CustomPaint with painter', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LeadDocumentUploadCard(),
        ),
      ),
    );

    final customPaintFinder = find.byType(CustomPaint);
    expect(customPaintFinder, findsWidgets);
  });
}
