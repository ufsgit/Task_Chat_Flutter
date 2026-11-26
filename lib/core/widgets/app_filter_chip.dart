import 'package:flutter/material.dart';
import '../theme.dart';

/// Universal filter chip widget across the entire application.
/// Styled according to the Today page reference specification.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final redAccent = isDark ? AppDarkColors.primaryRed : AppColors.primaryRed;

    final chipBg = isSelected
        ? (isDark ? AppDarkColors.chipPendingBg : AppColors.chipPendingBg)
        : Colors.transparent;

    final chipTextColor = isSelected
        ? (isDark ? AppDarkColors.offWhite : AppDarkColors.darkGrey)
        : (isDark ? AppDarkColors.mutedSilver : AppColors.chipUnselectedText);

    final unselectedBorderColor = isDark
        ? AppDarkColors.border
        : const Color(0xFFCBD5E1);

    final selectedBorderColor = redAccent.withValues(alpha: isDark ? 0.40 : 0.30);

    final chipBorder = isSelected
        ? Border.all(color: selectedBorderColor, width: 1.2)
        : Border.all(color: unselectedBorderColor, width: 1.5);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(18),
          border: chipBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: chipTextColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Helvetica Neue',
                color: chipTextColor,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
