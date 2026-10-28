import 'package:flutter/material.dart';
import 'customer_header_card.dart';

export 'customer_header_card.dart' show openDialer, openWhatsApp;

/// Backward-compatibility wrapper/alias for the unified contact info section.
class ContactActionsCard extends StatelessWidget {
  final dynamic customer;
  final VoidCallback? onCallTap;
  final VoidCallback? onMessageTap;

  const ContactActionsCard({
    super.key,
    required this.customer,
    this.onCallTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomerHeaderCard(
      customer: customer,
      onCallTap: onCallTap,
      onMessageTap: onMessageTap,
    );
  }
}
