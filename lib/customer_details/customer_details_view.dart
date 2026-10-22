import 'package:flutter/material.dart';
import '../core/circular_back_button.dart';
import '../core/slide_up_route.dart';
import '../core/theme.dart';
import '../update_status/super_admin_update_status_page.dart';
import '../update_status/update_status_page.dart';
import 'customer_details_model.dart';
import 'customer_details_view_model.dart';
import 'widgets/contact_actions_card.dart';
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
    final updatedStatus = await Navigator.push<String>(
      context,
      SlideUpRoute(
        page: widget.isCoordinator
            ? CoordinatorUpdateStatusPage(customer: _viewModel.customer)
            : UpdateStatusPage(customer: _viewModel.customer),
      ),
    );

    if (updatedStatus != null && mounted) {
      _viewModel.updateStatus(updatedStatus);
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
    final nameController = TextEditingController(
      text: _viewModel.customer.name,
    );
    final phoneController = TextEditingController(
      text: _viewModel.customer.phoneNumber,
    );
    final initialAddress = _viewModel.customer.addressLine2.isNotEmpty
        ? '${_viewModel.customer.addressLine1}, ${_viewModel.customer.addressLine2}'
        : _viewModel.customer.addressLine1;
    final addressController = TextEditingController(text: initialAddress);
    final notesController = TextEditingController(
      text: _viewModel.customer.notes,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimary;
    final secondaryTextColor = isDark
        ? AppDarkColors.textSecondary
        : AppColors.textSecondary;
    final cardBg = isDark ? AppDarkColors.surfaceCard : Colors.white;

    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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
                controller: nameController,
                style: TextStyle(color: primaryTextColor),
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Customer Name',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                style: TextStyle(color: primaryTextColor),
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: 'Phone Number',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                maxLines: 2,
                style: TextStyle(color: primaryTextColor),
                decoration: const InputDecoration(
                  labelText: 'Address',
                  hintText: 'Address',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
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
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Helvetica Neue',
                color: secondaryTextColor,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
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
      ),
    );

    if (updated == true && mounted) {
      final success = await _viewModel.updateCustomer(
        name: nameController.text.trim(),
        phoneNumber: phoneController.text.trim(),
        address: addressController.text.trim(),
        notes: notesController.text.trim(),
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

        return Scaffold(
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
                  onBack: () => Navigator.of(context).pop(customer.status),
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
                      // 1. Customer Name & Inquiry Header Card
                      CustomerHeaderCard(customer: customer),

                      const SizedBox(height: 16),

                      // 2. Contact Phone, Actions, Address & Notes Card
                      ContactActionsCard(customer: customer),

                      const SizedBox(height: 16),

                      // 3. Attached Documents Card
                      CustomerDocumentsCard(documents: customer.documents),

                      const SizedBox(height: 24),

                      // 4. Full-width Update Status Button opens the Update Status Page
                      UpdateStatusButton(onTap: _openUpdateStatusPage),
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
        );
      },
    );
  }
}

/// Backward compatibility alias for CustomerDetailsView.
typedef CustomerDetailsPage = CustomerDetailsView;
