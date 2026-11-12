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
  final VoidCallback? onTap;

  const AppPillNotification({
    super.key,
    required this.message,
    this.icon,
    this.iconColor,
    this.textStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Center(
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
                  color:
                      iconColor ??
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
                  style:
                      textStyle ??
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

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}

/// Unified API to trigger pill notifications anywhere in the app.
class AppNotification {
  AppNotification._();

  /// Default bottom margin when positioned above the floating bottom navigation bar.
  /// The floating bottom bar is 68px tall + 14px bottom padding = 82px.
  /// 104px provides a clean ~22px floating clearance directly above it.
  static const double kAboveBottomNavMargin = 104.0;
  static const double kDefaultBottomMargin = 24.0;

  /// Shows the pill notification toast at the bottom of the screen.
  static void show(
    BuildContext context,
    String message, {
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(milliseconds: 2200),
    VoidCallback? onTap,
    bool aboveBottomNav = false,
    double? bottomMargin,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final bottomPadding = MediaQuery.maybePaddingOf(context)?.bottom ?? 0.0;
    final effectiveBottomMargin =
        bottomMargin ??
        (aboveBottomNav
            ? (kAboveBottomNavMargin + bottomPadding)
            : kDefaultBottomMargin);

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        margin: EdgeInsets.only(
          bottom: effectiveBottomMargin,
          left: 16,
          right: 16,
        ),
        duration: duration,
        content: AppPillNotification(
          message: message,
          icon: icon,
          iconColor: iconColor,
          onTap: onTap != null
              ? () {
                  messenger.hideCurrentSnackBar();
                  onTap();
                }
              : null,
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
    bool aboveBottomNav = true,
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
      aboveBottomNav: aboveBottomNav,
    );
  }

  /// Convenience helper for contact deleted notifications matching status change design.
  static void showContactDeleted(
    BuildContext context, {
    String message = 'Contact deleted successfully',
    String? customerName,
    bool aboveBottomNav = true,
  }) {
    final displayMessage = customerName != null && customerName.isNotEmpty
        ? 'Contact "$customerName" deleted successfully'
        : message;
    show(
      context,
      displayMessage,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.primaryGreen,
      aboveBottomNav: aboveBottomNav,
    );
  }

  /// Convenience helper for new booking saved notifications matching status change design.
  static void showBookingSaved(
    BuildContext context, {
    String message = 'Booking saved successfully!',
    String? customerName,
    bool aboveBottomNav = true,
  }) {
    final displayMessage =
        customerName != null && customerName.trim().isNotEmpty
        ? 'Booking saved for ${customerName.trim()}'
        : message;
    show(
      context,
      displayMessage,
      icon: Icons.check_circle_rounded,
      iconColor: AppColors.primaryGreen,
      aboveBottomNav: aboveBottomNav,
    );
  }

  /// Convenience helper for error alerts.
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    bool aboveBottomNav = false,
  }) {
    show(
      context,
      message,
      icon: Icons.error_outline_rounded,
      iconColor: const Color(0xFFEF4444),
      duration: duration,
      aboveBottomNav: aboveBottomNav,
    );
  }
}
