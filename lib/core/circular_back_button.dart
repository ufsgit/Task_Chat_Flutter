import 'package:flutter/material.dart';
import 'theme.dart';

/// Reusable circular back button matching the style used in Update Status.
/// Features a circular white container, subtle border, gentle shadow,
/// and green chevron icon.
class CircularBackButton extends StatelessWidget {
  final VoidCallback? onBack;
  final Color? iconColor;
  final double size;

  const CircularBackButton({
    super.key,
    this.onBack,
    this.iconColor,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onBack ??
              () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark ? AppDarkColors.surfaceCard : AppColors.surfaceWhite,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppDarkColors.border : AppColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : AppColors.textPrimary.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 1.5),
                child: Icon(
                  Icons.chevron_left_rounded,
                  color: iconColor ??
                      (isDark ? AppDarkColors.whatsappGreen : AppColors.brandGreen),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
