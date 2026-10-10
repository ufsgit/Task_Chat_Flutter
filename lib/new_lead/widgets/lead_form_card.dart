import 'package:flutter/material.dart';

/// A reusable white card container with rounded corners and subtle shadow.
class LeadFormCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const LeadFormCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}
