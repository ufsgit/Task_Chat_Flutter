import 'package:flutter/material.dart';
import '../theme.dart';

/// Reusable floating pill notification widget matching the clean,
/// compact capsule design from the mockup.
///
/// Designed with appropriate size (compact, content-wrapping pill)
/// to display status updates, notifications, and alert messages.
class AppPillNotification extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final TextStyle? textStyle;

  const AppPillNotification({
    super.key,
    required this.message,
    this.icon,
    this.iconColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surfaceCard : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ??
                      (isDark
                          ? AppDarkColors.primaryGreen
                          : AppColors.primaryGreen),
                ),
                const SizedBox(width: 9),
              ],
              Flexible(
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: textStyle ??
                      TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppDarkColors.textPrimary
                            : const Color(0xFF0F172A),
                        letterSpacing: -0.1,
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

/// Unified API to trigger pill notifications anywhere in the app.
class AppNotification {
  AppNotification._();

  /// Shows the pill notification toast at the bottom of the screen.
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: duration,
        content: AppPillNotification(
          message: message,
          icon: icon,
          iconColor: iconColor,
        ),
      ),
    );
  }

  /// Convenience helper for status change success notifications.
  static void showStatusChange(
    BuildContext context, {
    required String status,
    required String customerName,
    String? assignment,
  }) {
    final assignmentSuffix =
        (assignment != null && assignment.trim().isNotEmpty)
            ? ' (Assigned: $assignment)'
            : '';
    show(
      context,
      'Status updated to $status for $customerName$assignmentSuffix',
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.primaryGreen,
    );
  }

  /// Convenience helper for error alerts.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      context,
      message,
      icon: Icons.error_outline_rounded,
      iconColor: const Color(0xFFEF4444),
      duration: duration,
    );
  }
}
