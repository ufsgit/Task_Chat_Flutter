import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/document_upload_service.dart';
import '../../core/theme.dart';
import '../../core/widgets/circular_back_button.dart';
import '../../core/widgets/document_preview_upload_page.dart';
import '../../new_booking/widgets/lead_document_upload_card.dart';
import '../../new_booking/widgets/lead_form_card.dart';
import '../../new_booking/widgets/lead_labeled_row.dart';
import '../customer_details_model.dart';

/// Data returned when editing a customer is submitted.
class EditCustomerData {
  final String name;
  final String phoneNumber;
  final String address;
  final String notes;
  final List<String> documents;

  const EditCustomerData({
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.notes,
    this.documents = const [],
  });
}

/// Backward compatibility alias for EditCustomerData
typedef EditContactDialogData = EditCustomerData;

/// Screen for editing an existing customer's contact information.
/// Uses the exact same card-based layout and style as the New Customer (add_booking) screen.
class EditCustomerView extends StatefulWidget {
  final CustomerDetailsData customer;
  final ValueChanged<EditCustomerData>? onSave;
  final VoidCallback? onCancel;

  const EditCustomerView({
    super.key,
    required this.customer,
    this.onSave,
    this.onCancel,
  });

  @override
  State<EditCustomerView> createState() => _EditCustomerViewState();
}

class _EditCustomerViewState extends State<EditCustomerView> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late List<String> _documents;
  final bool _isUploadingDocument = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _phoneController = TextEditingController(text: widget.customer.phoneNumber);
    final initialAddress = widget.customer.addressLine2.isNotEmpty
        ? '${widget.customer.addressLine1}, ${widget.customer.addressLine2}'
        : widget.customer.addressLine1;
    _addressController = TextEditingController(text: initialAddress);
    _notesController = TextEditingController(text: widget.customer.notes);
    _documents = List<String>.from(widget.customer.documents);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleSave() {
    final data = EditCustomerData(
      name: _nameController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
      documents: _documents,
    );

    if (widget.onSave != null) {
      widget.onSave!(data);
    } else {
      Navigator.of(context).pop(data);
    }
  }

  Future<void> _handlePickDocuments() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'png', 'jpg', 'jpeg'],
      );

      if (files.isNotEmpty && mounted) {
        final uploadService = DocumentUploadService();

        for (final file in files) {
          if (!mounted) break;

          List<int>? bytes;
          try {
            bytes = await file.readAsBytes();
          } catch (_) {}

          if (!mounted) break;

          final uploadedUrl = await Navigator.of(context).push<String>(
            MaterialPageRoute(
              builder: (context) => DocumentPreviewUploadPage(
                fileName: file.name,
                filePath: file.path,
                fileBytes: bytes != null ? Uint8List.fromList(bytes) : null,
                uploadService: uploadService,
              ),
            ),
          );

          if (!mounted) break;

          if (uploadedUrl != null) {
            setState(() {
              if (!_documents.contains(uploadedUrl)) {
                _documents.add(uploadedUrl);
              }
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Document "${file.name}" uploaded successfully',
                  style: const TextStyle(fontFamily: 'Helvetica Neue'),
                ),
                backgroundColor: AppColors.whatsappGreen,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('FilePicker error: $e');
    }
  }

  Future<void> _handlePreviewDocument(String doc) async {
    final fileName = doc.split('/').last.isNotEmpty ? doc.split('/').last : doc;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            DocumentPreviewUploadPage(fileName: fileName, fileUrl: doc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppDarkColors.textPrimary
        : const Color(0xFF0F172A);
    final subtitleTextColor = isDark
        ? AppDarkColors.textSubtitle
        : const Color(0xFF475569);
    final placeholderColor = isDark
        ? AppDarkColors.textPlaceholder
        : const Color(0xFF94A3B8);
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(child: CircularBackButton(onBack: _handleCancel)),
        ),
        title: Text(
          'Edit Contact',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        titleSpacing: 8,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Full Name Card
              LeadFormCard(
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: primaryTextColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    hintStyle: TextStyle(color: placeholderColor),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Mobile Card
              LeadFormCard(
                child: LeadLabeledRow(
                  label: 'Mobile',
                  controller: _phoneController,
                  hintText: 'Mobile number',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                  ],
                  maxLength: 15,
                ),
              ),
              const SizedBox(height: 14),

              // 3. Address & Notes Card
              LeadFormCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LeadLabeledRow(
                      label: 'Address',
                      controller: _addressController,
                      hintText: 'Address',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(
                        height: 1,
                        thickness: 0.6,
                        color: isDark
                            ? AppDarkColors.divider
                            : const Color(0xFFF1F5F9),
                      ),
                    ),
                    Text(
                      'Customer Notes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppDarkColors.textPrimary
                            : const Color(0xFF334155),
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Add client requirements, background, or preferred contact time...',
                        hintStyle: TextStyle(
                          color: placeholderColor,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Attach Documents Card
              LeadDocumentUploadCard(
                documents: _documents,
                isUploading: _isUploadingDocument,
                onTap: _isUploadingDocument ? null : _handlePickDocuments,
                onPreview: _handlePreviewDocument,
                onRemove: (doc) {
                  setState(() {
                    _documents.remove(doc);
                  });
                },
              ),
              const SizedBox(height: 28),

              // 5. Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.whatsappGreen,
                    foregroundColor: isDark
                        ? const Color(0xFF0B141B)
                        : Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 6. Cancel Button
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleCancel,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: subtitleTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
