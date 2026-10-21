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

/// Metric summary card data model matching the modern dashboard cards design.
class MetricCardData {
  final String title;
  final String value;
  final String? subtitle;
  final Color titleColor;
  final IconData leadingIcon;
  final Color iconBgColor;
  final Color? iconColor;
  final Color cardBgColor;
  final Color? darkCardBgColor;
  final Color? sparklineColor;
  final String? percentageText;
  final Color? percentageColor;
  final double? progressValue;
  final Color? progressColor;

  const MetricCardData({
    required this.title,
    required this.value,
    this.subtitle,
    required this.titleColor,
    required this.leadingIcon,
    required this.iconBgColor,
    this.iconColor,
    required this.cardBgColor,
    this.darkCardBgColor,
    this.sparklineColor,
    this.percentageText,
    this.percentageColor,
    this.progressValue,
    this.progressColor,
  });
}

// -----------------------------------------------------------------------------
// Dashboard Initial / Mock Data
// -----------------------------------------------------------------------------

/// Time range filters.
const List<String> defaultTimeFilters = ['All', 'This Month', 'Last 30 Days'];

/// Default booking progress card data.
const BookingProgressData defaultBookingProgress = BookingProgressData(
  title: 'New Booking',
  badgeText: 'NEW',
  totalLeads: 48,
  progressPercent: 0.68,
);

/// Default new booking metrics card data (Top Left).
const MetricCardData defaultNewBookingMetric = MetricCardData(
  title: 'New Booking',
  value: '48',
  subtitle: 'New bookings per month',
  titleColor: Color(0xFF84CC16),
  leadingIcon: Icons.person_add_alt_1_rounded,
  iconBgColor: Color(0xFF1D61E7),
  iconColor: Color(0xFFA3E635),
  cardBgColor: Color(0xFFF2F7FE),
  darkCardBgColor: Color.fromARGB(255, 36, 36, 41),
);

/// Default pending metrics card data (Top Right).
const MetricCardData defaultPendingMetric = MetricCardData(
  title: 'Pending',
  value: '19',
  subtitle: 'Pending follow-ups per month',
  titleColor: Color(0xFFF97316),
  leadingIcon: Icons.hourglass_empty_rounded,
  iconBgColor: Color.fromARGB(255, 109, 19, 211),
  iconColor: Colors.purple,
  cardBgColor: Color.fromARGB(255, 235, 225, 243),
  darkCardBgColor: Color.fromARGB(255, 36, 36, 41),
);

/// Default completed metrics data (Bottom Left).
const MetricCardData defaultCompletedMetric = MetricCardData(
  title: 'Completed',
  value: '31',
  subtitle: 'Completed orders per month',
  titleColor: Color(0xFF34D399),
  leadingIcon: Icons.check_circle_outline_rounded,
  iconBgColor: Color(0xFF15803D),
  iconColor: Colors.green,
  cardBgColor: Color(0xFFEFFBF3),
  darkCardBgColor: Color.fromARGB(255, 36, 36, 41),
);

/// Default scheduled metrics data (Bottom Right).
const MetricCardData defaultScheduledMetric = MetricCardData(
  title: 'Scheduled',
  value: '35',
  subtitle: 'Scheduled visits per month',
  titleColor: Color(0xFFFBBF24),
  leadingIcon: Icons.calendar_today_rounded,
  iconBgColor: Color(0xFFB45309),
  iconColor: Colors.orange,
  cardBgColor: Color(0xFFFFF9EC),
  darkCardBgColor: Color.fromARGB(255, 36, 36, 41),
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
