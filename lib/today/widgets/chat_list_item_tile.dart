import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Reusable list tile widget for rendering a redesigned lead or task item.
/// Decoupled from data models and styling logic.
class ChatListItemTile extends StatelessWidget {
  final String title;
  final String avatarLetter;
  final Color avatarBgColor;
  final Color avatarTextColor;
  final Color? avatarBorderColor;
  final bool hasVerifiedBadge;
  final Color indicatorColor;
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
    required this.avatarLetter,
    this.avatarBgColor = AppColors.surfaceGrey,
    this.avatarTextColor = AppColors.textSecondary,
    this.avatarBorderColor,
    this.hasVerifiedBadge = false,
    this.indicatorColor = Colors.transparent,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left rounded vertical indicator bar
              Container(
                width: 3.5,
                height: 28,
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              _buildAvatar(),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          date,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

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
                            color: tagBgColor,
                            borderRadius: BorderRadius.circular(4.5),
                          ),
                          child: Text(
                            tagText,
                            style: TextStyle(
                              color: tagTextColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Location pin icon
                        const Icon(
                          Icons.location_on_outlined,
                          size: 15,
                          color: AppColors.textSubtitle,
                        ),
                        const SizedBox(width: 3),

                        // Location name
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSubtitle,
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

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: avatarBgColor,
            shape: BoxShape.circle,
            border: avatarBorderColor != null
                ? Border.all(color: avatarBorderColor!, width: 1.5)
                : null,
          ),
          child: Center(
            child: Text(
              avatarLetter,
              style: TextStyle(
                color: avatarTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (hasVerifiedBadge)
          Positioned(
            right: -2,
            bottom: -1,
            child: Container(
              width: 17,
              height: 17,
              decoration: BoxDecoration(
                color: AppColors.verifiedBadge,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Center(
                child: Icon(Icons.check, size: 10, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
