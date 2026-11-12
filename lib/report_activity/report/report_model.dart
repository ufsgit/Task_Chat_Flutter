/// Model for booking status activity reports returned by /api/reports/bookings.
class BookingReportGraphItem {
  final String periodLabel;
  final String periodDate;
  final int newCount;
  final int scheduledCount;
  final int completedCount;
  final int cancelledCount;
  final int totalActivities;

  const BookingReportGraphItem({
    required this.periodLabel,
    required this.periodDate,
    required this.newCount,
    required this.scheduledCount,
    required this.completedCount,
    required this.cancelledCount,
    required this.totalActivities,
  });

  factory BookingReportGraphItem.fromJson(Map<String, dynamic> json) {
    return BookingReportGraphItem(
      periodLabel: json['periodLabel']?.toString() ?? '',
      periodDate: json['periodDate']?.toString() ?? '',
      newCount: _parseInt(json['newCount']),
      scheduledCount: _parseInt(json['scheduledCount']),
      completedCount: _parseInt(json['completedCount']),
      cancelledCount: _parseInt(json['cancelledCount']),
      totalActivities: _parseInt(json['totalActivities']),
    );
  }

  static int _parseInt(dynamic val) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val != null) return int.tryParse(val.toString()) ?? 0;
    return 0;
  }
}
