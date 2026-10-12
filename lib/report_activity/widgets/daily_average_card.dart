import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../task_report_data.dart';
import 'task_bar_chart.dart';

/// Card 1: Daily Average Metric, Stacked Bar Chart, Legend & Footer.
class DailyAverageCard extends StatelessWidget {
  final DailyAverageSummary summary;

  const DailyAverageCard({
    super.key,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header: "DAILY AVERAGE" + "+24% finished" pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DAILY AVERAGE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textSubtitle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7F0),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_outward_rounded,
                      size: 13,
                      color: AppColors.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      summary.badgeText,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Large Value: "14 Tasks / day"
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${summary.dailyAverage} Tasks',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                '/ day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSubtitle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. Stacked Bar Chart
          TaskBarChart(
            data: summary.weeklyBreakdown,
            maxY: summary.maxY,
            averageLine: summary.averageLine,
          ),

          const SizedBox(height: 22),

          // 4. Metric Legend Row (Completed, Pending, In Progress)
          Row(
            children: [
              Expanded(
                child: _buildLegendPill(
                  dotColor: AppColors.primaryGreen,
                  title: 'Completed',
                  value: '${summary.completedTasks} Tasks',
                  valueColor: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLegendPill(
                  dotColor: const Color(0xFFF97316),
                  title: 'Pending',
                  value: '${summary.pendingTasks} Tasks',
                  valueColor: const Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildLegendPill(
                  dotColor: const Color(0xFF2563EB),
                  title: 'In Progress',
                  value: '${summary.inProgressTasks} Tasks',
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 5. Card Footer: Total Tasks Managed & Timestamp
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textPrimary,
                    ),
                    children: [
                      const TextSpan(
                        text: 'Total Tasks Managed: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: '${summary.totalTasksManaged} Tasks',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: AppColors.textPlaceholder,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    summary.lastUpdatedText,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill({
    required Color dotColor,
    required String title,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDF2F7), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSubtitle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: valueColor,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
