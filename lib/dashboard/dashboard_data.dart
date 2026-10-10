import 'package:flutter/material.dart';

/// Performance data model for each day in the weekly performance chart.
class DayPerformanceData {
  final String day;
  final double completed;
  final double newBooking;
  final bool isPeak;

  const DayPerformanceData({
    required this.day,
    required this.completed,
    required this.newBooking,
    this.isPeak = false,
  });
}

/// Lead progress metric model.
class BookingProgressData {
  final String title;
  final String badgeText;
  final int totalLeads;
  final double progressPercent;

  const BookingProgressData({
    required this.title,
    required this.badgeText,
    required this.totalLeads,
    required this.progressPercent,
  });
}

/// Metric summary card data model.
class MetricCardData {
  final String title;
  final String value;
  final String? footerText;
  final IconData leadingIcon;
  final IconData? footerIcon;
  final Color cardBgColor;
  final Color borderColor;
  final Color accentColor;

  const MetricCardData({
    required this.title,
    required this.value,
    this.footerText,
    required this.leadingIcon,
    this.footerIcon,
    required this.cardBgColor,
    required this.borderColor,
    required this.accentColor,
  });
}

// -----------------------------------------------------------------------------
// Dashboard Initial / Mock Data
// -----------------------------------------------------------------------------

/// Time range filters.
const List<String> defaultTimeFilters = [
  'This Week',
  'This Month',
  'Last 30 Days',
];

/// Default booking progress card data.
const BookingProgressData defaultBookingProgress = BookingProgressData(
  title: 'New Booking',
  badgeText: 'NEW',
  totalLeads: 48,
  progressPercent: 0.68,
);

/// Default completed metrics data.
const MetricCardData defaultCompletedMetric = MetricCardData(
  title: 'Completed',
  value: '31',
  footerText: '64.5% rate',
  leadingIcon: Icons.handshake_outlined,
  footerIcon: Icons.timelapse_rounded,
  cardBgColor: Color(0xFFF0FDF4),
  borderColor: Color(0xFFDCFCE7),
  accentColor: Color(0xFF15803D),
);

/// Default scheduled metrics data.
const MetricCardData defaultScheduledMetric = MetricCardData(
  title: 'Scheduled',
  value: '35',
  footerText: null,
  leadingIcon: Icons.verified_outlined,
  footerIcon: Icons.check_circle_outline_rounded,
  cardBgColor: Color(0xFFFFFBEB),
  borderColor: Color(0xFFFEF3C7),
  accentColor: Color(0xFFD97706),
);

/// Weekly performance chart data matching the reference design.
const List<DayPerformanceData> defaultWeeklyPerformance = [
  DayPerformanceData(day: 'Mon', completed: 6.0, newBooking: 3.5),
  DayPerformanceData(day: 'Tue', completed: 8.0, newBooking: 5.5),
  DayPerformanceData(day: 'Wed', completed: 10.0, newBooking: 7.5),
  DayPerformanceData(day: 'Thu', completed: 12.5, newBooking: 9.5),
  DayPerformanceData(day: 'Fri', completed: 6.5, newBooking: 4.2),
  DayPerformanceData(day: 'Sat', completed: 3.8, newBooking: 2.0),
  DayPerformanceData(day: 'Sun', completed: 2.4, newBooking: 1.3),
];
