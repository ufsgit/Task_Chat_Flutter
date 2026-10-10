import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../dashboard_data.dart';

/// Reusable Weekly Performance Dual-Bar Chart Card for Dashboard.
/// Completely overflow-free with precise layout geometry.
class WeeklyPerformanceChartCard extends StatelessWidget {
  final List<DayPerformanceData> data;
  final String title;
  final String filterBadgeText;
  final VoidCallback? onBadgeTap;

  const WeeklyPerformanceChartCard({
    super.key,
    required this.data,
    this.title = 'Weekly Performance',
    this.filterBadgeText = 'Total Completed',
    this.onBadgeTap,
  });

  static const double _barAreaHeight = 135.0;
  static const double _maxBarHeight = 96.0;

  @override
  Widget build(BuildContext context) {
    // Find maximum Y value for scale, default to 15.0
    final maxDataValue = data.fold<double>(
      0.0,
      (max, item) => [
        max,
        item.completed,
        item.newBooking,
      ].reduce((a, b) => a > b ? a : b),
    );
    final maxY = maxDataValue > 15.0
        ? ((maxDataValue / 5).ceil() * 5).toDouble()
        : 15.0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Icon + Title
          Row(
            children: [
              const Icon(
                Icons.bar_chart_rounded,
                size: 22,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onBadgeTap,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.completedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        filterBadgeText,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.completedText,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Legend: Completed (green) & New booking (blue)
          Row(
            children: [
              _buildLegendItem(
                color: const Color(0xFF16A34A),
                label: 'Completed',
              ),
              const SizedBox(width: 16),
              _buildLegendItem(
                color: const Color(0xFF2563EB),
                label: 'New booking',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main Chart: Left Y-Axis labels + Day Columns
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Y-Axis labels (15, 10, 5, 0)
              _buildYAxisLabels(),
              const SizedBox(width: 8),

              // Day Columns Area
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((dayItem) {
                    return _buildDayColumn(dayItem: dayItem, maxY: maxY);
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.5),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildYAxisLabels() {
    return SizedBox(
      height: _barAreaHeight,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '15',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSubtitle,
            ),
          ),
          Text(
            '10',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSubtitle,
            ),
          ),
          Text(
            '5',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSubtitle,
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 4.0),
            child: Text(
              '0',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSubtitle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayColumn({
    required DayPerformanceData dayItem,
    required double maxY,
  }) {
    final completedHeight = (dayItem.completed / maxY) * _maxBarHeight;
    final newBookingHeight = (dayItem.newBooking / maxY) * _maxBarHeight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Fixed-height bar area to prevent any overflow
        SizedBox(
          height: _barAreaHeight,
          width: 34,
          child: dayItem.isPeak
              ? Container(
                  padding: const EdgeInsets.only(
                    top: 6,
                    bottom: 4,
                    left: 4,
                    right: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7).withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      // Peak Pill Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Peak',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Bars
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildBar(completedHeight, const Color(0xFF16A34A)),
                          const SizedBox(width: 3),
                          _buildBar(newBookingHeight, const Color(0xFF2563EB)),
                        ],
                      ),
                    ],
                  ),
                )
              : Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBar(completedHeight, const Color(0xFF16A34A)),
                        const SizedBox(width: 3),
                        _buildBar(newBookingHeight, const Color(0xFF2563EB)),
                      ],
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 6),

        // Day Label (Mon, Tue, Thu...)
        SizedBox(
          height: 16,
          child: Text(
            dayItem.day,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: dayItem.isPeak ? FontWeight.w700 : FontWeight.w500,
              color: dayItem.isPeak
                  ? const Color(0xFF15803D)
                  : AppColors.textSubtitle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 8,
      height: height.clamp(3.0, _maxBarHeight),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }
}
