import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';
import '../api/document_upload_service.dart';
import '../core/widgets/app_pill_notification.dart';
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
import 'widgets/edit_customer_view.dart';
import 'widgets/update_status_button.dart';

export 'widgets/edit_customer_view.dart';

/// Customer Details / Contact Info screen matching the design.
/// Follows MVVM architecture with CustomerDetailsViewModel.
class CustomerDetailsView extends StatefulWidget {
  final CustomerDetailsModel customer;
  final bool isCoordinator;
  final CustomerDetailsViewModel? viewModel;
  final bool? autoFetch;

  const CustomerDetailsView({
    super.key,
    required this.customer,
    this.viewModel,
    this.autoFetch,
    bool? isCoordinator,
  }) : isCoordinator = isCoordinator ?? false;

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
    if (widget.autoFetch == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchLatestDetails();
      });
    }
  }

  Future<void> _fetchLatestDetails() async {
    final success = await _viewModel.fetchCustomerDetails();
    if (!success && mounted) {
      AppNotification.showError(
        context,
        _viewModel.fetchError ?? 'Failed to update',
      );
    }
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
              AppNotification.show(
                context,
                'Document "${file.name}" uploaded successfully',
                icon: Icons.check_circle_rounded,
                iconColor: AppColors.primaryGreen,
              );
            } else if (!success && mounted) {
              AppNotification.showError(
                context,
                _viewModel.updateError ?? 'Failed to update',
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
        AppNotification.showContactDeleted(context, aboveBottomNav: true);
        Navigator.of(context).pop('DELETED');
      } else {
        AppNotification.showError(
          context,
          _viewModel.deleteError ?? 'Failed to delete contact',
        );
      }
    }
  }

  Future<void> _handleEditContact() async {
    final result = await Navigator.of(context).push<EditCustomerData>(
      SlideUpRoute(page: EditCustomerView(customer: _viewModel.customer)),
    );

    if (result != null && mounted) {
      final success = await _viewModel.updateCustomer(
        name: result.name,
        phoneNumber: result.phoneNumber,
        address: result.address,
        notes: result.notes,
        documents: result.documents,
      );

      if (!mounted) return;

      if (success) {
        AppNotification.show(
          context,
          'Contact updated successfully',
          icon: Icons.check_circle_rounded,
          iconColor: AppColors.primaryGreen,
        );
      } else {
        AppNotification.showError(
          context,
          _viewModel.updateError ?? 'Failed to update contact',
        );
      }
    }
  }

  Future<void> _handleDataSharing() async {
    final success = await _viewModel.shareDataToWhatsApp();
    if (!success && mounted) {
      AppNotification.showError(context, 'Could not open WhatsApp for sharing');
    }
  }

  Future<void> _handleBrochureSharing() async {
    try {
      AppNotification.show(
        context,
        'Loading brochures...',
        icon: Icons.downloading_rounded,
        iconColor: AppColors.primaryGreen,
      );

      final brochures = await _viewModel.fetchBrochureItems();
      if (!mounted) return;

      if (brochures.isEmpty) {
        AppNotification.showError(
          context,
          'Failed to load doc',
        );
        return;
      }

      List<String> selectedUrls;
      if (brochures.length == 1) {
        selectedUrls = [brochures.first.url];
      } else {
        final chosen = await _showBrochureSelectionSheet(brochures);
        if (chosen == null || chosen.isEmpty || !mounted) {
          return;
        }
        selectedUrls = chosen;
      }

      final bool success = await _runWithLoadingFilesDialog(
        label: selectedUrls.length > 1
            ? 'Preparing brochures...'
            : 'Preparing brochure...',
        task: () => _viewModel.shareBrochureFromLink(
          overrideDocUrls: selectedUrls,
        ),
      );
      if (!success && mounted) {
        AppNotification.showError(
          context,
          'Failed to load doc',
        );
      }
    } catch (e) {
      debugPrint('Error sharing brochure: $e');
      if (mounted) {
        AppNotification.showError(context, 'Failed to load doc');
      }
    }
  }

  Future<T> _runWithLoadingFilesDialog<T>({
    required String label,
    required Future<T> Function() task,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppDarkColors.surfaceCard : Colors.white;
    final textPrimary =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;

    bool dialogOpen = true;
    late final AppLifecycleListener lifecycleListener;
    void closeDialog() {
      if (dialogOpen && mounted) {
        dialogOpen = false;
        Navigator.of(context, rootNavigator: true).pop();
      }
    }

    lifecycleListener = AppLifecycleListener(
      onInactive: closeDialog,
    );

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 90,
                    width: 240,
                    child: Lottie.asset(
                      'assets/animations/loading_files.json',
                      fit: BoxFit.contain,
                      repeat: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      dialogOpen = false;
    });

    try {
      return await task();
    } finally {
      lifecycleListener.dispose();
      closeDialog();
    }
  }

  Future<List<String>?> _showBrochureSelectionSheet(
    List<BrochureItem> brochures,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceBg = isDark ? AppDarkColors.surfaceCard : Colors.white;
    final textPrimary =
        isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final textSecondary =
        isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
    final borderColor = isDark ? AppDarkColors.border : AppColors.border;

    final selected = brochures.map((b) => b.url).toSet();

    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allSelected = selected.length == brochures.length;
            return SafeArea(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.72,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: borderColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Select brochures to share',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                if (allSelected) {
                                  selected.clear();
                                } else {
                                  selected.addAll(brochures.map((b) => b.url));
                                }
                              });
                            },
                            child: Text(
                              allSelected ? 'Clear all' : 'Select all',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: brochures.length,
                          separatorBuilder: (_, _) =>
                              Divider(height: 1, color: borderColor),
                          itemBuilder: (context, index) {
                            final item = brochures[index];
                            final isChecked = selected.contains(item.url);
                            final lower = (item.fileName ?? item.url).toLowerCase();
                            final IconData fileIcon = lower.endsWith('.pdf')
                                ? Icons.picture_as_pdf_rounded
                                : (lower.endsWith('.png') ||
                                        lower.endsWith('.jpg') ||
                                        lower.endsWith('.jpeg') ||
                                        lower.endsWith('.webp'))
                                    ? Icons.image_rounded
                                    : Icons.insert_drive_file_rounded;

                            return CheckboxListTile(
                              value: isChecked,
                              activeColor: AppColors.primaryGreen,
                              contentPadding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              controlAffinity: ListTileControlAffinity.trailing,
                              secondary: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  fileIcon,
                                  size: 20,
                                  color: AppColors.primaryGreen,
                                ),
                              ),
                              title: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                              subtitle: item.fileName != null &&
                                      item.fileName != item.title
                                  ? Text(
                                      item.fileName!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    )
                                  : null,
                              onChanged: (checked) {
                                setModalState(() {
                                  if (checked == true) {
                                    selected.add(item.url);
                                  } else {
                                    selected.remove(item.url);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(sheetContext).pop(null),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: selected.isEmpty
                                  ? null
                                  : () => Navigator.of(
                                        sheetContext,
                                      ).pop(selected.toList()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryGreen,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Send (${selected.length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
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
                  key: const ValueKey('share_contact_popup_button'),
                  tooltip: 'Share',
                  color: scaffoldBg,
                  surfaceTintColor: Colors.transparent,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: borderColor, width: 1),
                  ),
                  icon: Icon(
                    Icons.share_outlined,
                    color: isDark
                        ? AppDarkColors.textSecondary
                        : primaryTextColor,
                    size: 22,
                  ),
                  onSelected: (value) {
                    if (value == 'data_sharing') {
                      _handleDataSharing();
                    } else if (value == 'brochure_sharing') {
                      _handleBrochureSharing();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'data_sharing',
                      child: Row(
                        children: [
                          Icon(
                            Icons.chat_outlined,
                            size: 18,
                            color: isDark
                                ? AppDarkColors.whatsappGreen
                                : AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Data sharing',
                            style: TextStyle(
                              fontFamily: 'Helvetica Neue',
                              color: primaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'brochure_sharing',
                      child: Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            size: 18,
                            color: isDark
                                ? AppDarkColors.whatsappGreen
                                : AppColors.primaryGreen,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Brochure sharing',
                            style: TextStyle(
                              fontFamily: 'Helvetica Neue',
                              color: primaryTextColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                    } else if (value == 'History' ||
                        value == 'Booking History') {
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
                  RefreshIndicator(
                    onRefresh: _fetchLatestDetails,
                    color: AppColors.primaryGreen,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
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
