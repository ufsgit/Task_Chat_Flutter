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

    final chipBg = isSelected
        ? (isDark ? AppColors.surfaceWhite : AppColors.chipPendingBg)
        : Colors.transparent;

    final chipTextColor = isDark
        ? (isSelected ? Colors.black : Colors.white)
        : (isSelected
              ? AppColors.chipPendingText
              : AppColors.chipUnselectedText);

    final unselectedBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.35)
        : const Color(0xFFCBD5E1);

    final selectedBorderColor = isDark
        ? AppColors.surfaceWhite
        : AppColors.brandGreen;

    final chipBorder = isSelected
        ? Border.all(color: selectedBorderColor, width: 1.5)
        : Border.all(color: unselectedBorderColor, width: 1.8);

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
