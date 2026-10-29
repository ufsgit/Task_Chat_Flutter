import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../api/document_upload_service.dart';
import '../core/widgets/circular_back_button.dart';
import '../core/widgets/document_preview_upload_page.dart';
import '../core/slide_up_route.dart';
import '../core/theme.dart';
import '../report_activity/activity/activity_model.dart';
import '../report_activity/activity/booking_history_page.dart';
import '../update_status/branch_manager/branch_manager_update_status_view.dart';
import '../update_status/coordinators/coordinator_update_status_view.dart';
import '../update_status/status_update_result.dart';
import 'customer_details_model.dart';
import 'customer_details_view_model.dart';
import 'widgets/customer_documents_card.dart';
import 'widgets/customer_header_card.dart';
import 'widgets/update_status_button.dart';

/// Customer Details / Contact Info screen matching the design.
/// Follows MVVM architecture with CustomerDetailsViewModel.
class CustomerDetailsView extends StatefulWidget {
  final CustomerDetailsModel customer;
  final bool isCoordinator;
  final CustomerDetailsViewModel? viewModel;

  bool get isSuperAdmin => isCoordinator;

  const CustomerDetailsView({
    super.key,
    required this.customer,
    this.viewModel,
    bool? isCoordinator,
    bool? isSuperAdmin,
  }) : isCoordinator = isCoordinator ?? isSuperAdmin ?? false;

  @override
  State<CustomerDetailsView> createState() => _CustomerDetailsViewState();
}

class _CustomerDetailsViewState extends State<CustomerDetailsView> {
  late final CustomerDetailsViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel =
        widget.viewModel ?? CustomerDetailsViewModel(customer: widget.customer);
  }

  @override
  void dispose() {
    if (widget.viewModel == null) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _openUpdateStatusPage() async {
    final result = await Navigator.push<dynamic>(
      context,
      SlideUpRoute(
        page: widget.isCoordinator
            ? CoordinatorUpdateStatusPage(
                customer: _viewModel.customer,
                client: _viewModel.client,
                tokenStorage: _viewModel.tokenStorage,
              )
            : UpdateStatusPage(
                customer: _viewModel.customer,
                client: _viewModel.client,
                tokenStorage: _viewModel.tokenStorage,
              ),
      ),
    );

    if (result != null && mounted) {
      if (result is StatusUpdateResult) {
        _viewModel.applyUpdate(result);
        Navigator.of(context).pop(result);
      } else if (result is String) {
        _viewModel.updateStatus(result);
        Navigator.of(context).pop(result);
      }
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

  Future<void> _handleUploadDocument() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'png', 'jpg', 'jpeg'],
      );

      if (files.isNotEmpty && mounted) {
        final uploadService = DocumentUploadService(
          client: _viewModel.client,
          tokenStorage: _viewModel.tokenStorage,
        );

        final nav = Navigator.of(context);

        for (final file in files) {
          List<int>? bytes;
          try {
            bytes = await file.readAsBytes();
          } catch (_) {}

          if (!mounted) break;

          final uploadedUrl = await nav.push<String>(
            MaterialPageRoute(
              builder: (context) => DocumentPreviewUploadPage(
                fileName: file.name,
                filePath: file.path,
                fileBytes: bytes != null ? Uint8List.fromList(bytes) : null,
                uploadService: uploadService,
                bookingId: _viewModel.customer.id,
              ),
            ),
          );

          if (!mounted) break;

          if (uploadedUrl != null) {
            final updatedDocs = List<String>.from(_viewModel.customer.documents)
              ..add(uploadedUrl);
            final success = await _viewModel.updateCustomer(
              documents: updatedDocs,
            );
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Document "${file.name}" uploaded successfully',
                  ),
                  backgroundColor: AppColors.primaryGreen,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Upload document error: $e');
    }
  }

  Future<void> _handleDeleteContact() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Delete Contact',
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete ${_viewModel.customer.name}?',
          style: const TextStyle(fontFamily: 'Helvetica Neue'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontFamily: 'Helvetica Neue'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                fontFamily: 'Helvetica Neue',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await _viewModel.deleteCustomer();
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact deleted successfully'),
            backgroundColor: AppColors.whatsappGreen,
          ),
        );
        Navigator.of(context).pop('DELETED');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel.deleteError ?? 'Failed to delete contact'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _handleEditContact() async {
    final result = await showDialog<_EditContactDialogData>(
      context: context,
      builder: (ctx) => _EditContactDialog(customer: _viewModel.customer),
    );

    if (result != null && mounted) {
      final success = await _viewModel.updateCustomer(
        name: result.name,
        phoneNumber: result.phoneNumber,
        address: result.address,
        notes: result.notes,
      );

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact updated successfully'),
            backgroundColor: AppColors.whatsappGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_viewModel.updateError ?? 'Failed to update contact'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final primaryTextColor = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimary;
    final borderColor = isDark ? AppDarkColors.border : AppColors.border;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final customer = _viewModel.customer;

        final resultPayload = StatusUpdateResult(
          status: customer.status,
          scheduleDate: customer.scheduleDate ?? '',
          notes: customer.notes,
          documents: customer.documents,
          branchManager: customer.branchHeadName,
        );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            Navigator.of(context).pop(resultPayload);
          },
          child: Scaffold(
            backgroundColor: scaffoldBg,
            appBar: AppBar(
              backgroundColor: scaffoldBg,
              elevation: 0,
              scrolledUnderElevation: 0,
              leadingWidth: 58,
              leading: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Center(
                  child: CircularBackButton(
                    onBack: () => Navigator.of(context).pop(resultPayload),
                  ),
                ),
              ),
              title: Text(
                'Contact Info',
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 18.5,
                  fontWeight: FontWeight.w600,
                  color: primaryTextColor,
                  letterSpacing: -0.2,
                ),
              ),
              titleSpacing: 8,
              actions: [
                PopupMenuButton<String>(
                  color: scaffoldBg,
                  surfaceTintColor: Colors.transparent,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: borderColor, width: 1),
                  ),
                  icon: Icon(
                    Icons.more_vert,
                    color: isDark
                        ? AppDarkColors.textSecondary
                        : primaryTextColor,
                    size: 22,
                  ),
                  onSelected: (value) {
                    if (value == 'Delete') {
                      _handleDeleteContact();
                    } else if (value == 'Edit' || value == 'Edit Contact') {
                      _handleEditContact();
                    } else if (value == 'History' || value == 'Booking History') {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (_) => BookingHistoryPage(
                            initialBooking: ActivityModel(
                              id: _viewModel.customer.id,
                              bookingId: int.tryParse(_viewModel.customer.id),
                              title: _viewModel.customer.name,
                              avatarLetter: _viewModel.customer.name.isNotEmpty
                                  ? _viewModel.customer.name[0].toUpperCase()
                                  : 'C',
                              avatarBgColor: const Color(0xFFDCFCE7),
                              avatarTextColor: const Color(0xFF16A34A),
                              date: _viewModel.customer.scheduleDate ?? 'Today',
                              statusTag: _viewModel.customer.status,
                              notes: _viewModel.customer.notes,
                              subtitleHighlight:
                                  _viewModel.customer.branchHeadName,
                              location: _viewModel.customer.addressLine2,
                            ),
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Action: $value'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'History',
                      child: Text(
                        'Booking History',
                        style: TextStyle(
                          fontFamily: 'Helvetica Neue',
                          color: primaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'Edit',
                      child: Text(
                        'Edit Contact',
                        style: TextStyle(
                          fontFamily: 'Helvetica Neue',
                          color: primaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    PopupMenuItem(
                      value: 'Delete',
                      child: Text(
                        'Delete Contact',
                        style: TextStyle(
                          fontFamily: 'Helvetica Neue',
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1.0),
                child: Container(height: 1.0, color: borderColor),
              ),
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Unified Contact Info Section (Name, Address, Phone number, Status, Note)
                        CustomerHeaderCard(customer: customer),

                        const SizedBox(height: 16),

                        // 2. Full-width Update Status Button opens the Update Status Page
                        UpdateStatusButton(onTap: _openUpdateStatusPage),

                        const SizedBox(height: 16),

                        // 3. Attached Documents Card
                        CustomerDocumentsCard(
                          documents: customer.documents,
                          onView: _handlePreviewDocument,
                          onUpload: _handleUploadDocument,
                        ),
                      ],
                    ),
                  ),
                  if (_viewModel.isDeleting)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      alignment: Alignment.center,
                      child: const CircularProgressIndicator(
                        color: AppColors.whatsappGreen,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Backward compatibility alias for CustomerDetailsView.
typedef CustomerDetailsPage = CustomerDetailsView;

class _EditContactDialogData {
  final String name;
  final String phoneNumber;
  final String address;
  final String notes;

  const _EditContactDialogData({
    required this.name,
    required this.phoneNumber,
    required this.address,
    required this.notes,
  });
}

class _EditContactDialog extends StatefulWidget {
  final CustomerDetailsModel customer;

  const _EditContactDialog({required this.customer});

  @override
  State<_EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<_EditContactDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimary;
    final secondaryTextColor = isDark
        ? AppDarkColors.textSecondary
        : AppColors.textSecondary;
    final cardBg = isDark ? AppDarkColors.surfaceCard : Colors.white;

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Edit Contact',
        style: TextStyle(
          fontFamily: 'Helvetica Neue',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: primaryTextColor,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: TextStyle(color: primaryTextColor),
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Customer Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              style: TextStyle(color: primaryTextColor),
              decoration: const InputDecoration(
                labelText: 'Phone',
                hintText: 'Phone Number',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              maxLines: 2,
              style: TextStyle(color: primaryTextColor),
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'Address',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 2,
              style: TextStyle(color: primaryTextColor),
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Notes',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              color: secondaryTextColor,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(
              _EditContactDialogData(
                name: _nameController.text.trim(),
                phoneNumber: _phoneController.text.trim(),
                address: _addressController.text.trim(),
                notes: _notesController.text.trim(),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.whatsappGreen,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Save',
            style: TextStyle(
              fontFamily: 'Helvetica Neue',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
