import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../settings_model.dart';

/// Reusable profile header card with circle avatar initials, verified badge,
/// phone number, active indicator, and edit action.
class ProfileHeaderCard extends StatelessWidget {
  final UserProfileData profile;
  final VoidCallback? onEdit;

  const ProfileHeaderCard({super.key, required this.profile, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppDarkColors.surfaceCard : Colors.white;
    final cardBorder = isDark ? AppDarkColors.border : const Color(0xFFE9EDEF);
    final primaryTextColor = isDark ? const Color(0xFFE9EDEF) : const Color(0xFF111B21);
    final subtextColor = isDark ? const Color(0xFF8696A0) : const Color(0xFF64748B);
    final avatarBg = isDark ? const Color(0xFF2A3942) : const Color(0xFFE2E8F0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Circle Avatar with initials "RS" and Edit badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: avatarBg,
                child: Text(
                  profile.initials,
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: primaryTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    padding: const EdgeInsets.all(4.5),
                    decoration: BoxDecoration(
                      color: isDark ? AppDarkColors.primaryGreen : AppColors.primaryGreen,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1F2C34) : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryGreen.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Profile Details: Name, verified icon, phone, online indicator
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        profile.name,
                        style: TextStyle(
                          fontFamily: 'Helvetica Neue',
                          fontSize: 16.5,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  profile.phone,
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                    color: subtextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
