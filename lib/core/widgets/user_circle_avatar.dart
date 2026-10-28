import 'package:flutter/material.dart';
import '../theme.dart';

/// Represents a background + icon color pair for circular avatars.
class AvatarColorPair {
  final Color background;
  final Color icon;

  const AvatarColorPair({required this.background, required this.icon});
}

/// Resolves avatar color pair based on status:
/// - Scheduled / In-Progress: warm amber (AppColors.scheduledBg, AppColors.scheduledText)
/// - Completed: soft emerald green (AppColors.completedBg, AppColors.completedText)
/// - New: soft blue (AppColors.newBg, AppColors.newText)
/// - Cancelled: soft red (AppColors.cancelledBg, AppColors.cancelledText)
/// - Pending: soft mint green (AppColors.chipPendingBg, AppColors.chipPendingText)
AvatarColorPair getAvatarColorsForStatus(
  String? status, {
  bool isDark = false,
}) {
  final normalized = status?.toLowerCase().trim() ?? '';

  if (normalized.contains('schedul') ||
      normalized == 'in-progress' ||
      normalized == 'in progress') {
    return AvatarColorPair(
      background: isDark ? AppDarkColors.scheduledBg : AppColors.scheduledBg,
      icon: isDark ? AppDarkColors.scheduledText : AppColors.scheduledText,
    );
  } else if (normalized.contains('complet')) {
    return AvatarColorPair(
      background: isDark ? AppDarkColors.completedBg : AppColors.completedBg,
      icon: isDark ? AppDarkColors.completedText : AppColors.completedText,
    );
  } else if (normalized.contains('cancel')) {
    return AvatarColorPair(
      background: isDark ? AppDarkColors.cancelledBg : AppColors.cancelledBg,
      icon: isDark ? AppDarkColors.cancelledText : AppColors.cancelledText,
    );
  } else if (normalized.contains('pend')) {
    return AvatarColorPair(
      background: isDark
          ? AppDarkColors.chipPendingBg
          : AppColors.chipPendingBg,
      icon: isDark ? AppDarkColors.chipPendingText : AppColors.chipPendingText,
    );
  } else if (normalized.contains('new')) {
    return AvatarColorPair(
      background: isDark ? AppDarkColors.newBg : AppColors.newBg,
      icon: isDark ? AppDarkColors.newText : AppColors.newText,
    );
  }

  // Fallback for empty or unknown status
  return AvatarColorPair(
    background: isDark ? AppDarkColors.newBg : AppColors.newBg,
    icon: isDark ? AppDarkColors.newText : AppColors.newText,
  );
}

/// Backward compatibility alias - resolves avatar colors based on status.
AvatarColorPair getAvatarColorsForName(
  String? nameOrStatus, {
  bool isDark = false,
}) {
  return getAvatarColorsForStatus(nameOrStatus, isDark: isDark);
}

/// Clean circular user avatar with background and icon color resolved by status.
class UserCircleAvatar extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? status;
  final String? name;

  const UserCircleAvatar({
    super.key,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
    this.status,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedStatus = (status != null && status!.trim().isNotEmpty)
        ? status
        : name;
    final colors = getAvatarColorsForStatus(resolvedStatus, isDark: isDark);
    final bg = backgroundColor ?? colors.background;
    final iconCol = iconColor ?? colors.icon;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Center(
        child: Icon(Icons.person_rounded, size: size * 0.58, color: iconCol),
      ),
    );
  }
}
