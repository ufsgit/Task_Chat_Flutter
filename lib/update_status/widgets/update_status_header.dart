import 'package:flutter/material.dart';
import '../../core/widgets/circular_back_button.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initialLetter =
        customerName.isNotEmpty ? customerName[0].toUpperCase() : 'A';

    return Row(
      children: [
        CircularBackButton(onBack: onBack),
        const SizedBox(width: 12),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.pillActiveBg : AppColors.surfaceWhite,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initialLetter,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: isDark
                  ? AppDarkColors.whatsappGreen
                  : AppColors.primaryGreen,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            customerName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}
