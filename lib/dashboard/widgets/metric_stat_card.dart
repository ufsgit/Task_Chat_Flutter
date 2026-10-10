import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../dashboard_data.dart';

/// Reusable stat card for metrics in Dashboard (Completed, Scheduled, etc.).
class MetricStatCard extends StatelessWidget {
  final MetricCardData data;
  final VoidCallback? onTap;

  const MetricStatCard({
    super.key,
    required this.data,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: data.cardBgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: data.borderColor,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header: Leading Icon + Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: data.borderColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  data.leadingIcon,
                  size: 16,
                  color: data.accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Metric Value
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),

          // Footer info (Percentage rate or status icon)
          if (data.footerText != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (data.footerIcon != null) ...[
                  Icon(
                    data.footerIcon,
                    size: 14,
                    color: data.accentColor,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  data.footerText!,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: data.accentColor,
                  ),
                ),
              ],
            )
          else if (data.footerIcon != null)
            Icon(
              data.footerIcon,
              size: 16,
              color: data.accentColor,
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}
