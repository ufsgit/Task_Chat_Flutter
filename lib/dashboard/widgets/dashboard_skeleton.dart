import 'package:flutter/material.dart';

/// Shimmering skeleton placeholder card for dashboard metric cards.
class DashboardMetricCardSkeleton extends StatelessWidget {
  const DashboardMetricCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? const Color.fromARGB(255, 36, 36, 41)
        : const Color(0xFFF8FAFC);
    final placeholderColor = isDark
        ? const Color(0xFF2E2E38)
        : const Color(0xFFE2E8F0);
    final borderColor = isDark
        ? const Color(0xFF2E2E32)
        : const Color(0xFFE2E8F0);

    return Container(
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
          // 1. Top Icon placeholder
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Title placeholder
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 10),

          // 3. Bold Metric Value placeholder
          Container(
            width: 60,
            height: 32,
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 12),

          // 4. Subtitle placeholder
          Container(
            width: 110,
            height: 11,
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}

/// 2x2 grid of metric skeleton cards matching the Dashboard layout.
class DashboardMetricsSkeletonGrid extends StatelessWidget {
  const DashboardMetricsSkeletonGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: DashboardMetricCardSkeleton()),
              SizedBox(width: 12),
              Expanded(child: DashboardMetricCardSkeleton()),
            ],
          ),
        ),
        SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: DashboardMetricCardSkeleton()),
              SizedBox(width: 12),
              Expanded(child: DashboardMetricCardSkeleton()),
            ],
          ),
        ),
      ],
    );
  }
}
