import 'package:flutter/material.dart';
import '../core/slide_up_route.dart';
import '../core/theme.dart';
import 'customer_details_data.dart';
import '../update_status/super_admin_update_status_page.dart';
import '../update_status/update_status_page.dart';
import 'widgets/contact_actions_card.dart';
import 'widgets/customer_header_card.dart';
import 'widgets/update_status_button.dart';

/// Customer Details / Contact Info screen matching the design.
/// Data is separated into `customer_details_data.dart`,
/// and UI widgets are modular and reusable.
class CustomerDetailsPage extends StatefulWidget {
  final CustomerDetailsData customer;
  final bool isSuperAdmin;

  const CustomerDetailsPage({
    super.key,
    required this.customer,
    this.isSuperAdmin = false,
  });

  @override
  State<CustomerDetailsPage> createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  late CustomerDetailsData _customer;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
  }

  Future<void> _openUpdateStatusPage() async {
    final updatedStatus = await Navigator.push<String>(
      context,
      SlideUpRoute(
        page: widget.isSuperAdmin
            ? SuperAdminUpdateStatusPage(customer: _customer)
            : UpdateStatusPage(customer: _customer),
      ),
    );

    if (updatedStatus != null && mounted) {
      setState(() {
        _customer = CustomerDetailsData(
          id: _customer.id,
          name: _customer.name,
          inquiry: _customer.inquiry,
          statusBadge: '• $updatedStatus Lead • Follow-up Due',
          phoneNumber: _customer.phoneNumber,
          addressLine1: _customer.addressLine1,
          addressLine2: _customer.addressLine2,
          notes: _customer.notes,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Contact Info',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            color: AppColors.dropdownBackground,
            surfaceTintColor: Colors.transparent,
            icon: const Icon(
              Icons.more_vert,
              color: AppColors.textPrimary,
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
              const PopupMenuItem(value: 'Edit', child: Text('Edit Info')),
              const PopupMenuItem(
                value: 'Delete',
                child: Text('Delete Contact'),
              ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            height: 1.0,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE2E8F0),
                  Color(0xFFCBD5E1),
                  Color(0xFF94A3B8),
                ],
              ),
            ),
          ),
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
              CustomerHeaderCard(customer: _customer),

              const SizedBox(height: 16),

              // 2. Contact Phone, Actions, Address & Notes Card
              ContactActionsCard(customer: _customer),

              const SizedBox(height: 24),

              // 3. Full-width Update Status Button opens the Update Status Page
              UpdateStatusButton(
                onTap: _openUpdateStatusPage,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
