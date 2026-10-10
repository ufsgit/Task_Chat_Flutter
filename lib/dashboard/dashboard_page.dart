import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'dashboard_data.dart';
import 'widgets/booking_progress_card.dart';
import 'widgets/dashboard_time_filter_bar.dart';
import 'widgets/metric_stat_card.dart';
import 'widgets/weekly_performance_chart_card.dart';

/// Dashboard performance & analytics screen matching the design.
class DashboardPage extends StatefulWidget {
  final VoidCallback? onBack;

  const DashboardPage({
    super.key,
    this.onBack,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedFilter = 'This Week';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceWhite,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 40,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12.0),
          child: IconButton(
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.brandGreen,
              size: 28,
            ),
            onPressed: () {
              if (widget.onBack != null) {
                widget.onBack!();
              } else if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ),
        ),
        titleSpacing: 4,
        title: const Text(
          'TaskChat',
          style: TextStyle(
            color: AppColors.brandGreen,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Time Range Filter Bar
              DashboardTimeFilterBar(
                filters: defaultTimeFilters,
                selectedFilter: _selectedFilter,
                onFilterSelected: (newFilter) {
                  setState(() {
                    _selectedFilter = newFilter;
                  });
                },
              ),
              const SizedBox(height: 16),

              // 2. New Booking Progress Card
              const BookingProgressCard(
                data: defaultBookingProgress,
              ),
              const SizedBox(height: 14),

              // 3. Metric Stats Row (Completed & Scheduled)
              const Row(
                children: [
                  Expanded(
                    child: MetricStatCard(
                      data: defaultCompletedMetric,
                    ),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: MetricStatCard(
                      data: defaultScheduledMetric,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 4. Weekly Performance Chart Card
              const WeeklyPerformanceChartCard(
                data: defaultWeeklyPerformance,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
