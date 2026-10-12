import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Reusable header displaying circular back button, customer initial avatar, and name.
class UpdateStatusHeader extends StatelessWidget {
  final String customerName;
  final VoidCallback onBack;

  const UpdateStatusHeader({
    super.key,
    required this.customerName,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final initialLetter =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : 'A';

    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceWhite,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.brandGreen,
              size: 26,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initialLetter,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryGreen,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            customerName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}
