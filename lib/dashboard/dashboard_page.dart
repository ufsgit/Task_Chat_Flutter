import 'package:flutter/material.dart';
import '../core/widgets/fitmate_app_bar_title.dart';
import 'dashboard_data.dart';
import 'widgets/dashboard_time_filter_bar.dart';
import 'widgets/metric_stat_card.dart';

/// Dashboard performance & analytics screen matching the design.
class DashboardPage extends StatefulWidget {
  final VoidCallback? onBack;

  const DashboardPage({super.key, this.onBack});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _selectedFilter = 'This Week';

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        toolbarHeight: 68,
        title: const FitmateAppBarTitle(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
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

              // 2. Metric Stats Row (New Booking & Pending)
              const IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: MetricStatCard(data: defaultNewBookingMetric),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: MetricStatCard(data: defaultPendingMetric)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 3. Metric Stats Row (Completed & Scheduled)
              const IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: MetricStatCard(data: defaultCompletedMetric),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: MetricStatCard(data: defaultScheduledMetric),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}
