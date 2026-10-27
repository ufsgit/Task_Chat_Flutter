import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';
import '../api/authenticated_client.dart';
import '../login_page/token_storage.dart';

// -----------------------------------------------------------------------------
// Period Enum & Constants
// -----------------------------------------------------------------------------

/// Available time range periods for Dashboard analytics.
enum DashboardPeriod {
  currentMonth,
  last30Days,
  allTime;

  /// User-facing label displayed on the filter chips.
  String get label {
    switch (this) {
      case DashboardPeriod.currentMonth:
        return 'Current Month';
      case DashboardPeriod.last30Days:
        return 'Last 30 Days';
      case DashboardPeriod.allTime:
        return 'All Time';
    }
  }

  /// Query parameter value expected by the backend API:
  /// Current Month: `period=this_month`
  /// Last 30 Days: `period=last_30_days`
  /// All Time: `period=all`
  String get queryValue {
    switch (this) {
      case DashboardPeriod.currentMonth:
        return 'this_month';
      case DashboardPeriod.last30Days:
        return 'last_30_days';
      case DashboardPeriod.allTime:
        return 'all';
    }
  }

  /// Subtitle description suffix for metric cards.
  String get subtitleSuffix {
    switch (this) {
      case DashboardPeriod.currentMonth:
        return 'per month';
      case DashboardPeriod.last30Days:
        return 'in last 30 days';
      case DashboardPeriod.allTime:
        return 'all time';
    }
  }

  /// Parses a string label (e.g. from filter chips or mock data) into a [DashboardPeriod].
  static DashboardPeriod fromLabel(String? label) {
    if (label == null) return DashboardPeriod.currentMonth;
    final normalized = label.trim().toLowerCase();
    if (normalized.contains('30') || normalized.contains('last')) {
      return DashboardPeriod.last30Days;
    }
    if (normalized == 'all' || normalized.contains('all time')) {
      return DashboardPeriod.allTime;
    }
    return DashboardPeriod.currentMonth;
  }
}

/// Time range filters labels.
const List<String> defaultTimeFilters = [
  'Current Month',
  'Last 30 Days',
  'All Time',
];

// -----------------------------------------------------------------------------
// Metric Card & Progress Data Models
// -----------------------------------------------------------------------------

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
// Default / Fallback Metrics Data
// -----------------------------------------------------------------------------

const BookingProgressData defaultBookingProgress = BookingProgressData(
  title: 'New Booking',
  badgeText: 'NEW',
  totalLeads: 48,
  progressPercent: 0.68,
);

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

const MetricCardData defaultCompletedMetric = MetricCardData(
  title: 'Completed',
  value: '31',
  subtitle: 'Completed orders per month',
  percentageText: '64.5%',
  percentageColor: Color(0xFF34D399),
  titleColor: Color(0xFF34D399),
  leadingIcon: Icons.check_circle_outline_rounded,
  iconBgColor: Color(0xFF15803D),
  iconColor: Colors.green,
  cardBgColor: Color(0xFFEFFBF3),
  darkCardBgColor: Color.fromARGB(255, 36, 36, 41),
);

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

const List<DayPerformanceData> defaultWeeklyPerformance = [
  DayPerformanceData(day: 'Mon', completed: 6.0, newBooking: 3.5),
  DayPerformanceData(day: 'Tue', completed: 8.0, newBooking: 5.5),
  DayPerformanceData(day: 'Wed', completed: 10.0, newBooking: 7.5),
  DayPerformanceData(day: 'Thu', completed: 12.5, newBooking: 9.5),
  DayPerformanceData(day: 'Fri', completed: 6.5, newBooking: 4.2),
  DayPerformanceData(day: 'Sat', completed: 3.8, newBooking: 2.0),
  DayPerformanceData(day: 'Sun', completed: 2.4, newBooking: 1.3),
];

// -----------------------------------------------------------------------------
// Dashboard Main Model
// -----------------------------------------------------------------------------

/// Data model representing metrics parsed from the dashboard metrics endpoint.
class DashboardModel {
  final int newBooking;
  final int pending;
  final int completed;
  final int scheduled;
  final int total;
  final Map<String, dynamic> rawJson;

  const DashboardModel({
    this.newBooking = 0,
    this.pending = 0,
    this.completed = 0,
    this.scheduled = 0,
    this.total = 0,
    this.rawJson = const {},
  });

  /// Resilient JSON factory parsing backend responses in various shapes:
  /// 1. Standard: `{ "success": true, "data": { "newBooking": 48, "pending": 19, ... } }`
  /// 2. Snake case: `{ "data": { "new_booking": 48, "pending": 19, ... } }`
  /// 3. Array of counts: `{ "data": [ { "status": "New", "count": 48 }, ... ] }`
  /// 4. Flat JSON: `{ "newBooking": 48, "pending": 19, ... }`
  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final dynamic rawData =
        json['data'] ?? json['counts'] ?? json['metrics'] ?? json;

    int newBookingCount = 0;
    int pendingCount = 0;
    int completedCount = 0;
    int scheduledCount = 0;
    int totalCount = 0;

    if (rawData is List) {
      for (final item in rawData) {
        if (item is Map) {
          final status = (item['status'] ??
                  item['code'] ??
                  item['label'] ??
                  item['name'] ??
                  '')
              .toString()
              .toLowerCase();
          final count =
              _parseInt(item['count'] ?? item['value'] ?? item['total']);

          if (status.contains('new')) {
            newBookingCount = count;
          } else if (status.contains('pend')) {
            pendingCount = count;
          } else if (status.contains('complete')) {
            completedCount = count;
          } else if (status.contains('schedul')) {
            scheduledCount = count;
          }
        }
      }
    } else if (rawData is Map) {
      final map = rawData;
      newBookingCount = _parseInt(
        map['newBooking'] ??
            map['new_booking'] ??
            map['new'] ??
            map['new_bookings'] ??
            map['newBookings'] ??
            map['New'],
      );

      pendingCount = _parseInt(
        map['pending'] ??
            map['pending_bookings'] ??
            map['pendingFollowUps'] ??
            map['pending_follow_ups'] ??
            map['Pending'],
      );

      completedCount = _parseInt(
        map['completed'] ??
            map['completed_bookings'] ??
            map['completedOrders'] ??
            map['completed_orders'] ??
            map['Completed'],
      );

      scheduledCount = _parseInt(
        map['scheduled'] ??
            map['scheduled_bookings'] ??
            map['scheduledVisits'] ??
            map['scheduled_visits'] ??
            map['Scheduled'],
      );

      totalCount = _parseInt(
        map['total'] ??
            map['total_bookings'] ??
            map['totalBookings'] ??
            map['totalLeads'],
      );
    }

    if (totalCount == 0) {
      totalCount =
          newBookingCount + pendingCount + completedCount + scheduledCount;
    }

    return DashboardModel(
      newBooking: newBookingCount,
      pending: pendingCount,
      completed: completedCount,
      scheduled: scheduledCount,
      total: totalCount,
      rawJson: json,
    );
  }

  /// Converts metric numbers into fully styled [MetricCardData] objects matching
  /// the design aesthetic and selected time period.
  MetricCardData toNewBookingCard({required DashboardPeriod period}) {
    return MetricCardData(
      title: 'New Booking',
      value: '$newBooking',
      subtitle: 'New bookings ${period.subtitleSuffix}',
      titleColor: const Color(0xFF84CC16),
      leadingIcon: Icons.person_add_alt_1_rounded,
      iconBgColor: const Color(0xFF1D61E7),
      iconColor: const Color(0xFFA3E635),
      cardBgColor: const Color(0xFFF2F7FE),
      darkCardBgColor: const Color.fromARGB(255, 36, 36, 41),
    );
  }

  MetricCardData toPendingCard({required DashboardPeriod period}) {
    return MetricCardData(
      title: 'Pending',
      value: '$pending',
      subtitle: 'Pending follow-ups ${period.subtitleSuffix}',
      titleColor: const Color(0xFFF97316),
      leadingIcon: Icons.hourglass_empty_rounded,
      iconBgColor: const Color.fromARGB(255, 109, 19, 211),
      iconColor: Colors.purple,
      cardBgColor: const Color.fromARGB(255, 235, 225, 243),
      darkCardBgColor: const Color.fromARGB(255, 36, 36, 41),
    );
  }

  MetricCardData toCompletedCard({required DashboardPeriod period}) {
    return MetricCardData(
      title: 'Completed',
      value: '$completed',
      subtitle: 'Completed orders ${period.subtitleSuffix}',
      titleColor: const Color(0xFF34D399),
      leadingIcon: Icons.check_circle_outline_rounded,
      iconBgColor: const Color(0xFF15803D),
      iconColor: Colors.green,
      cardBgColor: const Color(0xFFEFFBF3),
      darkCardBgColor: const Color.fromARGB(255, 36, 36, 41),
    );
  }

  MetricCardData toScheduledCard({required DashboardPeriod period}) {
    return MetricCardData(
      title: 'Scheduled',
      value: '$scheduled',
      subtitle: 'Scheduled visits ${period.subtitleSuffix}',
      titleColor: const Color(0xFFFBBF24),
      leadingIcon: Icons.calendar_today_rounded,
      iconBgColor: const Color(0xFFB45309),
      iconColor: Colors.orange,
      cardBgColor: const Color(0xFFFFF9EC),
      darkCardBgColor: const Color.fromARGB(255, 36, 36, 41),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? (double.tryParse(value)?.toInt() ?? 0);
    }
    return 0;
  }
}

// -----------------------------------------------------------------------------
// Dashboard Service (Data Source)
// -----------------------------------------------------------------------------

/// Service responsible for fetching analytics & performance data from
/// GET /api/mobile-dashboard/metrics?period={this_month|last_30_days|all}.
class DashboardService {
  final http.Client client;
  final TokenStorage tokenStorage;

  DashboardService({
    http.Client? client,
    TokenStorage? tokenStorage,
  })  : client = client ?? AuthenticatedClient(),
        tokenStorage = tokenStorage ?? TokenStorage();

  /// Calls GET ApiConfig.dashboard?period=`period.queryValue`
  Future<DashboardModel> fetchDashboard({
    DashboardPeriod period = DashboardPeriod.currentMonth,
  }) async {
    final isTest = TokenStorage.isTestEnvironment;
    String? token;
    try {
      token = await tokenStorage.getToken().timeout(
        isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 5),
      );
    } catch (_) {}

    final baseUri = Uri.parse(ApiConfig.dashboard);
    final uri = baseUri.replace(
      queryParameters: {
        'period': period.queryValue,
      },
    );

    final response = await client.get(
      uri,
      headers: {
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization':
              token.startsWith('Bearer ') ? token : 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final dynamic decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        return DashboardModel.fromJson(decoded);
      } else if (decoded is List) {
        return DashboardModel.fromJson({'data': decoded});
      }
      return const DashboardModel();
    } else {
      throw Exception(
          'Failed to load dashboard metrics (${response.statusCode})');
    }
  }
}
