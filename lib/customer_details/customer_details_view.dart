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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Action: $value'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'Edit',
                    child: Text(
                      'Edit Info',
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
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  const CustomerDocumentsCard(),

                  const SizedBox(height: 24),

                  // 4. Full-width Update Status Button opens the Update Status Page
                  UpdateStatusButton(onTap: _openUpdateStatusPage),
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
