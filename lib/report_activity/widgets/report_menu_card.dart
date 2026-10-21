import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../report_data.dart';

/// Reusable card component for the Report & Activity landing screen.
class ReportMenuCard extends StatelessWidget {
  final ReportMenuItemData item;
  final VoidCallback? onTap;

  const ReportMenuCard({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppDarkColors.surfaceCard : AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppDarkColors.border : AppColors.border,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              // Leading Logo / Icon Badge with image fallback
              Image.asset(
                item.imageAsset,
                width: 54,
                height: 54,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF233138)
                          : item.fallbackBg,
                      shape: BoxShape.circle,
                      border: item.hasBorderOnFallback
                          ? Border.all(
                              color: isDark
                                  ? AppDarkColors.whatsappGreen
                                  : const Color(0xFFFDE68A),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: Icon(
                      item.fallbackIcon,
                      color: isDark
                          ? AppDarkColors.whatsappGreen
                          : item.fallbackIconColor,
                      size: 28,
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),

              // Title Text
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppDarkColors.textPrimary
                        : AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
