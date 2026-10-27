import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/widgets/document_preview_upload_page.dart';
import 'package:task_chat/api/document_upload_service.dart';

class FakeUploadService extends DocumentUploadService {
  final String fakeUrl;
  bool uploadCalled = false;

  FakeUploadService({this.fakeUrl = 'https://example.com/uploaded_file.pdf'});

  @override
  Future<String> uploadFile({
    required String fileName,
    List<int>? bytes,
    String? filePath,
    dynamic bookingId,
    String fieldName = 'files',
  }) async {
    uploadCalled = true;
    return fakeUrl;
  }
}

void main() {
  testWidgets('DocumentPreviewUploadPage renders Cancel and Upload buttons when uploadService is provided', (tester) async {
    final fakeService = FakeUploadService();
    String? returnedResult;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                returnedResult = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (context) => DocumentPreviewUploadPage(
                      fileName: 'sample_contract.pdf',
                      filePath: '/dummy/sample_contract.pdf',
                      fileBytes: Uint8List.fromList([1, 2, 3, 4]),
                      uploadService: fakeService,
                    ),
                  ),
                );
              },
              child: const Text('Open Preview'),
            );
          },
        ),
      ),
    );

    // Tap to open preview page
    await tester.tap(find.text('Open Preview'));
    await tester.pumpAndSettle();

    // Verify page content
    expect(find.text('Upload Document Preview'), findsOneWidget);
    expect(find.text('sample_contract.pdf'), findsAtLeastNWidgets(1));
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);

    // Tap Upload
    await tester.tap(find.text('Upload'));
    await tester.pumpAndSettle();

    // Verify upload was invoked and returned the URL
    expect(fakeService.uploadCalled, isTrue);
    expect(returnedResult, 'https://example.com/uploaded_file.pdf');
  });

  testWidgets('DocumentPreviewUploadPage pops null when Cancel button is tapped', (tester) async {
    final fakeService = FakeUploadService();
    String? returnedResult = 'initial';

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () async {
                returnedResult = await Navigator.of(context).push<String>(
                  MaterialPageRoute(
                    builder: (context) => DocumentPreviewUploadPage(
                      fileName: 'test_image.png',
                      filePath: '/dummy/test_image.png',
                      fileBytes: Uint8List.fromList([1, 2, 3]),
                      uploadService: fakeService,
                    ),
                  ),
                );
              },
              child: const Text('Open Preview'),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open Preview'));
    await tester.pumpAndSettle();

    expect(find.text('Cancel'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    // Verify canceled without uploading
    expect(fakeService.uploadCalled, isFalse);
    expect(returnedResult, isNull);
  });

  testWidgets('DocumentPreviewUploadPage renders in view-only mode when fileUrl is passed', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DocumentPreviewUploadPage(
          fileName: 'existing_invoice.pdf',
          fileUrl: '/uploads/existing_invoice.pdf',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Document Preview'), findsOneWidget);
    expect(find.text('existing_invoice.pdf'), findsAtLeastNWidgets(1));
    // Upload button shouldn't exist in view mode
    expect(find.text('Upload'), findsNothing);
  });
}
