import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../activity_data.dart';

/// Reusable card widget for displaying an activity record.
class ActivityItemCard extends StatelessWidget {
  final ActivityItemData item;
  final VoidCallback? onTap;

  const ActivityItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppDarkColors.surfaceCard : AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppDarkColors.border : AppColors.border,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Circular Avatar Badge
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: item.avatarBgColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                item.avatarLetter,
                style: TextStyle(
                  color: item.avatarTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Main Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Title + Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppDarkColors.textPrimary
                            : AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      item.date,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppDarkColors.textSubtitle
                            : AppColors.textSubtitle,
                      ),
                    ),
                  ],
                ),

                // Optional Subtitle (e.g. Rescheduled by Sita Sharma)
                if (item.subtitlePrefix != null) ...[
                  const SizedBox(height: 3),
                  RichText(
                    text: TextSpan(
                      text: item.subtitlePrefix,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppDarkColors.textSubtitle
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        if (item.subtitleHighlight != null)
                          TextSpan(
                            text: item.subtitleHighlight,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppDarkColors.textPrimary
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // Optional Status Pill (e.g. Completed with checkmark)
                if (item.statusTag != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: item.statusTagBg ?? AppColors.completedBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.statusTagIcon != null) ...[
                          Icon(
                            item.statusTagIcon,
                            size: 14,
                            color:
                                item.statusTagTextColor ??
                                AppColors.completedText,
                          ),
                          const SizedBox(width: 5),
                        ],
                        Text(
                          item.statusTag!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color:
                                item.statusTagTextColor ??
                                AppColors.completedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Optional Sub-card / Note box (e.g. Rescheduled to monday, Tomorrow 10:00 AM...)
                if (item.noteText != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppDarkColors.surfaceSecondary
                          : AppColors.surfaceWhite,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppDarkColors.border : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        if (item.noteIcon != null) ...[
                          Icon(
                            item.noteIcon,
                            size: 16,
                            color:
                                item.noteIconColor ??
                                (isDark
                                    ? AppDarkColors.textSubtitle
                                    : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            item.noteText!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: item.subtitlePrefix != null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDark
                                  ? AppDarkColors.textPrimary
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
