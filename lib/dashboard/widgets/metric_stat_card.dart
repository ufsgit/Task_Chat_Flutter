import 'package:flutter/material.dart';
import '../dashboard_data.dart';

/// Reusable stat card for metrics in Dashboard (New Booking, Pending, Completed, Scheduled)
/// matching the exact screenshot design: dark forest/charcoal container, top icon + status dot,
/// white title and value, and muted sage subtitle.
class MetricStatCard extends StatelessWidget {
  final MetricCardData data;
  final VoidCallback? onTap;

  const MetricStatCard({super.key, required this.data, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark
        ? (data.darkCardBgColor ?? const Color.fromARGB(255, 36, 36, 41))
        : data.cardBgColor;
    final borderColor = isDark
        ? const Color(0xFF2E2E32)
        : data.titleColor.withValues(alpha: 0.12);
    final iconColor =
        data.iconColor ?? (isDark ? Colors.white : data.titleColor);
    final titleColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final numberColor = isDark ? Colors.white : data.titleColor;
    final subtitleColor = isDark
        ? const Color(0xFFA1A1AA)
        : const Color(0xFF64748B);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.0),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. Top Row: Leading Icon on Left & Status Dot on Right
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [Icon(data.leadingIcon, size: 24, color: iconColor)],
            ),
            const SizedBox(height: 14),

            // 2. Metric Title
            Text(
              data.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Helvetica Neue',
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: titleColor,
                letterSpacing: -0.1,
              ),
            ),
            const SizedBox(height: 6),

            // 3. Bold Main Metric Value (Clean White in Dark Mode)
            Text(
              data.value,
              style: TextStyle(
                fontFamily: 'Helvetica Neue',
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: numberColor,
                height: 1.0,
                letterSpacing: -0.5,
              ),
            ),

            // 4. Subtitle Description (Muted sage in Dark Mode)
            if (data.subtitle != null && data.subtitle!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                data.subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Helvetica Neue',
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: subtitleColor,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
