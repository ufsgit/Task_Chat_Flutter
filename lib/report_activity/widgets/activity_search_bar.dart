import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Reusable search input field for the Activity screen.
class ActivitySearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const ActivitySearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceCard : const Color(0xFFE6EEF5),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppDarkColors.border, width: 1) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        textAlignVertical: TextAlignVertical.center,
        onChanged: onChanged,
        style: TextStyle(
          color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search activity history...',
          hintStyle: TextStyle(
            color: isDark
                ? AppDarkColors.textPlaceholder
                : const Color(0xFF64748B),
            fontSize: 14.5,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    controller.clear();
                    onClear?.call();
                  },
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: isDark
                        ? AppDarkColors.textSubtitle
                        : const Color(0xFF64748B),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
