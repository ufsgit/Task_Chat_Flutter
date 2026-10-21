import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/user_circle_avatar.dart';

/// Reusable list tile widget for rendering a redesigned lead or task item.
/// Decoupled from data models and styling logic.
class ChatListItemTile extends StatelessWidget {
  final String title;
  final String avatarLetter;
  final Color avatarBgColor;
  final Color avatarTextColor;
  final Color? avatarBorderColor;
  final bool hasVerifiedBadge;
  final String date;
  final String tagText;
  final Color tagBgColor;
  final Color tagTextColor;
  final String location;
  final String? extraBadgeText;
  final Color? extraBadgeBgColor;
  final Color? extraBadgeTextColor;
  final VoidCallback? onTap;

  const ChatListItemTile({
    super.key,
    required this.title,
    this.avatarLetter = '',
    this.avatarBgColor = AppColors.surfaceGrey,
    this.avatarTextColor = AppColors.textSecondary,
    this.avatarBorderColor,
    this.hasVerifiedBadge = false,
    required this.date,
    required this.tagText,
    this.tagBgColor = AppColors.completedBg,
    this.tagTextColor = AppColors.completedText,
    required this.location,
    this.extraBadgeText,
    this.extraBadgeBgColor,
    this.extraBadgeTextColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final subtextColor = isDark ? AppDarkColors.textSubtitle : AppColors.textSubtitle;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              _buildAvatar(isDark),
              const SizedBox(width: 14),

              // Middle: Title + Date (Row) and Tag + Location (Row)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Row: Title + Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Helvetica Neue',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                            letterSpacing: -0.1,
                          ),
                        ),
                        Text(
                          date,
                          style: TextStyle(
                            fontFamily: 'Helvetica Neue',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: subtextColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Bottom Row: Tag + Location
                    Row(
                      children: [
                        // Tag pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? (tagText.toLowerCase() == 'completed'
                                    ? AppDarkColors.completedBg
                                    : (tagText.toLowerCase() == 'cancelled'
                                        ? AppDarkColors.cancelledBg
                                        : (tagText.toLowerCase() == 'new'
                                            ? AppDarkColors.newBg
                                            : AppDarkColors.surfaceSecondary)))
                                : tagBgColor,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            tagText,
                            style: TextStyle(
                              fontFamily: 'Helvetica Neue',
                              color: isDark
                                  ? (tagText.toLowerCase() == 'completed'
                                      ? AppDarkColors.completedText
                                      : (tagText.toLowerCase() == 'cancelled'
                                          ? AppDarkColors.cancelledText
                                          : (tagText.toLowerCase() == 'new'
                                              ? AppDarkColors.newText
                                              : AppDarkColors.textPrimary)))
                                  : tagTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Location pin icon
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: subtextColor,
                        ),
                        const SizedBox(width: 3),

                        // Location name
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Helvetica Neue',
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: subtextColor,
                            ),
                          ),
                        ),

                        // Optional extra badge (e.g. 'Branch Manager' for Super Admin)
                        if (extraBadgeText != null && extraBadgeText!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2.5,
                            ),
                            decoration: BoxDecoration(
                              color: extraBadgeBgColor ?? const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              extraBadgeText!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: extraBadgeTextColor ?? AppColors.primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(bool isDark) {
    return const UserCircleAvatar(size: 48);
  }
}
