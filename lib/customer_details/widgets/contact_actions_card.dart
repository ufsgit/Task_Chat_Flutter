import 'package:flutter/material.dart';
import 'customer_header_card.dart';

export 'customer_header_card.dart' show openDialer, openWhatsApp, openMap;

/// Backward-compatibility wrapper/alias for the unified contact info section.
class ContactActionsCard extends StatelessWidget {
  final dynamic customer;
  final VoidCallback? onCallTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onMapTap;

  const ContactActionsCard({
    super.key,
    required this.customer,
    this.onCallTap,
    this.onMessageTap,
    this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomerHeaderCard(
      customer: customer,
      onCallTap: onCallTap,
      onMessageTap: onMessageTap,
      onMapTap: onMapTap,
    );
  }
}
