import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../task_report_data.dart';

/// Card 3: Staff Performance list section with progress breakdown.
class StaffPerformanceCard extends StatelessWidget {
  final List<StaffPerformanceItem> staffList;
  final VoidCallback? onShowAllTap;
  final ValueChanged<StaffPerformanceItem>? onStaffTap;

  const StaffPerformanceCard({
    super.key,
    required this.staffList,
    this.onShowAllTap,
    this.onStaffTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
    final subtitleTextColor = isDark ? AppDarkColors.textSubtitle : AppColors.textSubtitle;
    final greenColor = isDark ? AppDarkColors.whatsappGreen : AppColors.primaryGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STAFF PERFORMANCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: subtitleTextColor,
              ),
            ),
            GestureDetector(
              onTap: onShowAllTap,
              child: Text(
                'Show All',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: greenColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // White Container Card
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppDarkColors.surfaceCard : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? AppDarkColors.border : AppColors.border,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.15)
                    : AppColors.textPrimary.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: List.generate(staffList.length, (index) {
              final staff = staffList[index];
              final isLast = index == staffList.length - 1;

              return Column(
                children: [
                  _buildStaffRow(context, staff, isDark, primaryTextColor, greenColor),
                  if (!isLast)
                    Divider(
                      height: 28,
                      thickness: 0.6,
                      color: isDark
                          ? AppDarkColors.divider
                          : const Color(0xFFF1F5F9),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildStaffRow(
    BuildContext context,
    StaffPerformanceItem staff,
    bool isDark,
    Color primaryTextColor,
    Color greenColor,
  ) {
    return InkWell(
      onTap: onStaffTap != null ? () => onStaffTap!(staff) : null,
      borderRadius: BorderRadius.circular(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 1. Initials Avatar Circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: staff.avatarBg,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              staff.initials,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                color: staff.avatarTextColor,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // 2. Middle Content (Name, Bar, Breakdown)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Total Tasks
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      staff.name,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: primaryTextColor,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      '${staff.totalTasks} Tasks',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Multi-Segmented Progress Bar + Chevron
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: SizedBox(
                          height: 6,
                          child: Row(
                            children: [
                              // Done (Green)
                              if (staff.doneTasks > 0)
                                Expanded(
                                  flex: staff.doneTasks,
                                  child: Container(
                                    color: AppColors.primaryGreen,
                                  ),
                                ),
                              if (staff.doneTasks > 0 &&
                                  (staff.pendingTasks > 0 || staff.inProgressTasks > 0))
                                const SizedBox(width: 2),
                              // Pending (Orange)
                              if (staff.pendingTasks > 0)
                                Expanded(
                                  flex: staff.pendingTasks,
                                  child: Container(
                                    color: const Color(0xFFF97316),
                                  ),
                                ),
                              if (staff.pendingTasks > 0 && staff.inProgressTasks > 0)
                                const SizedBox(width: 2),
                              // In Progress (Blue)
                              if (staff.inProgressTasks > 0)
                                Expanded(
                                  flex: staff.inProgressTasks,
                                  child: Container(
                                    color: const Color(0xFF0284C7),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: Color(0xFFCBD5E1),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Breakdown Legend Row
                Row(
                  children: [
                    _buildSubMetric(
                      dotColor: greenColor,
                      label: '${staff.doneTasks} Done',
                      labelColor: greenColor,
                    ),
                    const SizedBox(width: 10),
                    _buildSubMetric(
                      dotColor: const Color(0xFFF97316),
                      label: '${staff.pendingTasks} Pending',
                      labelColor: const Color(0xFFEA580C),
                    ),
                    const SizedBox(width: 10),
                    _buildSubMetric(
                      dotColor: const Color(0xFF0284C7),
                      label: '${staff.inProgressTasks} In Progress',
                      labelColor: const Color(0xFF0284C7),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubMetric({
    required Color dotColor,
    required String label,
    required Color labelColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: labelColor,
          ),
        ),
      ],
    );
  }
}
