import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../notification_data.dart';

/// Single notification item tile widget matching WhatsApp dark/light styling.
/// Includes optional red urgency indicator on the far left edge,
/// stylized colored avatar with initials, status tag badge, location pin, and timestamp.
class NotificationItemTile extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback? onTap;

  const NotificationItemTile({
    super.key,
    required this.item,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppDarkColors.textPrimary : const Color(0xFF0F172A);
    final subtextColor =
        isDark ? AppDarkColors.textSubtitle : const Color(0xFF64748B);
    final dividerColor =
        isDark ? AppDarkColors.divider : const Color(0xFFF1F5F9);

    final avatarBg = isDark
        ? item.avatarTextColor.withValues(alpha: 0.22)
        : item.avatarBgColor;
    final avatarFg = item.avatarTextColor;

    final tagBg = isDark
        ? (item.tag.toLowerCase() == 'new'
            ? AppDarkColors.newBg
            : AppDarkColors.surfaceSecondary)
        : item.tagBgColor;
    final tagFg = isDark
        ? (item.tag.toLowerCase() == 'new'
            ? AppDarkColors.newText
            : AppDarkColors.textPrimary)
        : item.tagTextColor;

    final timestampColor =
        item.isTimestampBold ? primaryTextColor : subtextColor;

    return InkWell(
      onTap: onTap,
      splashColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      highlightColor: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: dividerColor, width: 0.8),
          ),
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Red priority indicator strip on the far left edge if present
            if (item.hasRedIndicator)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 4,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(3),
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),

            // Main Tile Content
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with colored background and letter initial(s)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      item.avatarInitial,
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: avatarFg,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name and Status / Location Row
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name
                        Text(
                          item.name,
                          style: TextStyle(
                            fontFamily: 'Helvetica Neue',
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: primaryTextColor,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),

                        // Status Tag & Location
                        Row(
                          children: [
                            // "New" badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color: tagBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.tag,
                                style: TextStyle(
                                  fontFamily: 'Helvetica Neue',
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: tagFg,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Location Pin Icon
                            Icon(
                              Icons.location_on_outlined,
                              size: 13.5,
                              color: subtextColor,
                            ),
                            const SizedBox(width: 2),

                            // Location text
                            Flexible(
                              child: Text(
                                item.location,
                                style: TextStyle(
                                  fontFamily: 'Helvetica Neue',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w400,
                                  color: subtextColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Trailing Timestamp
                  Text(
                    item.timestamp,
                    style: TextStyle(
                      fontFamily: 'Helvetica Neue',
                      fontSize: 12,
                      fontWeight: item.isTimestampBold
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: timestampColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
