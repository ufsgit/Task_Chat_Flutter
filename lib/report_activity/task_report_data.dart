import 'package:flutter/material.dart';
import '../core/theme.dart';

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

// -----------------------------------------------------------------------------
// Mock / Default Data strictly matching the reference design
// -----------------------------------------------------------------------------

final TaskReportData defaultTaskReportData = TaskReportData(
  weekTitle: 'This Week',
  dateRange: 'Nov 10 – Nov 16',
  dailyAverage: DailyAverageSummary(
    badgeText: '+24% finished',
    dailyAverage: 14,
    completedTasks: 68,
    pendingTasks: 22,
    inProgressTasks: 8,
    totalTasksManaged: 98,
    lastUpdatedText: 'Today, 8:20 PM',
    averageLine: 14.0,
    maxY: 20.0,
    weeklyBreakdown: const [
      DayTaskBarItem(
        day: 'S',
        completed: 7.5,
        pending: 3.5,
        inProgress: 1.5,
      ),
      DayTaskBarItem(
        day: 'M',
        completed: 12.0,
        pending: 3.0,
        inProgress: 2.5,
      ),
      DayTaskBarItem(
        day: 'T',
        completed: 10.0,
        pending: 4.0,
        inProgress: 2.0,
      ),
      DayTaskBarItem(
        day: 'W',
        completed: 13.5,
        pending: 3.5,
        inProgress: 1.5,
        isCurrentDay: true,
      ),
      DayTaskBarItem(
        day: 'T',
        completed: 3.8,
        pending: 1.4,
        inProgress: 0.0,
        isPartial: true,
      ),
      DayTaskBarItem(
        day: 'F',
        completed: 0.0,
        pending: 0.0,
        inProgress: 0.0,
      ),
      DayTaskBarItem(
        day: 'S',
        completed: 0.0,
        pending: 0.0,
        inProgress: 0.0,
      ),
    ],
  ),
  attentionEfficiency: const AttentionEfficiencyData(
    title: 'Completion Rate',
    subtitle: '75.5% tasks done on schedule',
    status: 'Good',
    completionRate: 0.755,
    pendingTasks: 22,
  ),
  staffList: const [
    StaffPerformanceItem(
      id: '1',
      name: 'Ramesh Kumar',
      initials: 'RK',
      avatarBg: Color(0xFFD1FAE5),
      avatarTextColor: AppColors.primaryGreen,
      totalTasks: 28,
      doneTasks: 22,
      pendingTasks: 4,
      inProgressTasks: 2,
    ),
    StaffPerformanceItem(
      id: '2',
      name: 'Dr. Sunita',
      initials: 'DS',
      avatarBg: Color(0xFFFFE4E6),
      avatarTextColor: Color(0xFFE11D48),
      totalTasks: 24,
      doneTasks: 19,
      pendingTasks: 2,
      inProgressTasks: 3,
    ),
    StaffPerformanceItem(
      id: '3',
      name: 'Sita Sharma',
      initials: 'SS',
      avatarBg: Color(0xFFFEF3C7),
      avatarTextColor: Color(0xFFD97706),
      totalTasks: 26,
      doneTasks: 16,
      pendingTasks: 8,
      inProgressTasks: 2,
    ),
    StaffPerformanceItem(
      id: '4',
      name: 'Vikram Patel',
      initials: 'VP',
      avatarBg: Color(0xFFE0E7FF),
      avatarTextColor: Color(0xFF4338CA),
      totalTasks: 20,
      doneTasks: 11,
      pendingTasks: 8,
      inProgressTasks: 1,
    ),
  ],
);
