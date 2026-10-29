import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Single day data model for the stacked bar chart in Task Report.
class DayTaskBarItem {
  final String day;
  final double completed;
  final double pending;
  final double inProgress;
  final bool isCurrentDay;
  final bool isPartial;

  const DayTaskBarItem({
    required this.day,
    required this.completed,
    required this.pending,
    required this.inProgress,
    this.isCurrentDay = false,
    this.isPartial = false,
  });

  double get total => completed + pending + inProgress;
}

/// Daily average summary data for the top metric and chart card.
class DailyAverageSummary {
  final String badgeText;
  final int dailyAverage;
  final int completedTasks;
  final int pendingTasks;
  final int inProgressTasks;
  final int totalTasksManaged;
  final String lastUpdatedText;
  final double averageLine;
  final double maxY;
  final List<DayTaskBarItem> weeklyBreakdown;

  const DailyAverageSummary({
    required this.badgeText,
    required this.dailyAverage,
    required this.completedTasks,
    required this.pendingTasks,
    required this.inProgressTasks,
    required this.totalTasksManaged,
    required this.lastUpdatedText,
    this.averageLine = 14.0,
    this.maxY = 20.0,
    required this.weeklyBreakdown,
  });
}

/// Attention & Efficiency metric data model.
class AttentionEfficiencyData {
  final String title;
  final String subtitle;
  final String status;
  final double completionRate;
  final int pendingTasks;

  const AttentionEfficiencyData({
    required this.title,
    required this.subtitle,
    required this.status,
    required this.completionRate,
    required this.pendingTasks,
  });
}

/// Staff individual performance data model.
class StaffPerformanceItem {
  final String id;
  final String name;
  final String initials;
  final Color avatarBg;
  final Color avatarTextColor;
  final int totalTasks;
  final int doneTasks;
  final int pendingTasks;
  final int inProgressTasks;

  const StaffPerformanceItem({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarBg,
    required this.avatarTextColor,
    required this.totalTasks,
    required this.doneTasks,
    required this.pendingTasks,
    required this.inProgressTasks,
  });
}

/// Root data model for the Task Report page.
class TaskReportData {
  final String weekTitle;
  final String dateRange;
  final DailyAverageSummary dailyAverage;
  final AttentionEfficiencyData attentionEfficiency;
  final List<StaffPerformanceItem> staffList;

  const TaskReportData({
    required this.weekTitle,
    required this.dateRange,
    required this.dailyAverage,
    required this.attentionEfficiency,
    required this.staffList,
  });
}

/// Default task report metrics.
const TaskReportData defaultTaskReportData = TaskReportData(
  weekTitle: 'This Week',
  dateRange: '08/04 - 08/10',
  dailyAverage: DailyAverageSummary(
    badgeText: 'Daily Average',
    dailyAverage: 12,
    completedTasks: 32,
    pendingTasks: 4,
    inProgressTasks: 18,
    totalTasksManaged: 54,
    lastUpdatedText: 'Updated today at 10:45 AM',
    averageLine: 14.0,
    maxY: 20.0,
    weeklyBreakdown: [
      DayTaskBarItem(day: 'M', completed: 6, pending: 2, inProgress: 4),
      DayTaskBarItem(day: 'T', completed: 10, pending: 1, inProgress: 3),
      DayTaskBarItem(day: 'W', completed: 8, pending: 0, inProgress: 6),
      DayTaskBarItem(
        day: 'T',
        completed: 12,
        pending: 2,
        inProgress: 4,
        isCurrentDay: true,
      ),
      DayTaskBarItem(day: 'F', completed: 5, pending: 3, inProgress: 2),
      DayTaskBarItem(
        day: 'S',
        completed: 4,
        pending: 1,
        inProgress: 1,
        isPartial: true,
      ),
      DayTaskBarItem(
        day: 'S',
        completed: 2,
        pending: 0,
        inProgress: 0,
        isPartial: true,
      ),
    ],
  ),
  attentionEfficiency: AttentionEfficiencyData(
    title: 'Attention & Efficiency',
    subtitle: 'Weekly Task Efficiency Score',
    status: 'Optimal',
    completionRate: 84.5,
    pendingTasks: 4,
  ),
  staffList: [
    StaffPerformanceItem(
      id: '1',
      name: 'Ravi Kumar',
      initials: 'RK',
      avatarBg: Color(0xFFDCFCE7),
      avatarTextColor: AppColors.primaryGreen,
      totalTasks: 24,
      doneTasks: 20,
      pendingTasks: 1,
      inProgressTasks: 3,
    ),
    StaffPerformanceItem(
      id: '2',
      name: 'Priya Sharma',
      initials: 'PS',
      avatarBg: Color(0xFFFEF3C7),
      avatarTextColor: Color(0xFFD97706),
      totalTasks: 18,
      doneTasks: 14,
      pendingTasks: 2,
      inProgressTasks: 2,
    ),
    StaffPerformanceItem(
      id: '3',
      name: 'Anand V.',
      initials: 'AV',
      avatarBg: Color(0xFFE0F2FE),
      avatarTextColor: Color(0xFF0284C7),
      totalTasks: 12,
      doneTasks: 8,
      pendingTasks: 1,
      inProgressTasks: 3,
    ),
  ],
);
