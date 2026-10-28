import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/theme.dart';
import '../core/widgets/fitmate_app_bar_title.dart';
import '../login_page/token_storage.dart';
import 'dashboard_view_model.dart';
import 'widgets/custom_date_range_picker_dialog.dart';
import 'widgets/dashboard_skeleton.dart';
import 'widgets/dashboard_time_filter_bar.dart';
import 'widgets/metric_stat_card.dart';

/// Dashboard performance & analytics screen built with MVVM architecture.
class DashboardView extends StatefulWidget {
  final VoidCallback? onBack;
  final DashboardViewModel? viewModel;
  final http.Client? client;
  final TokenStorage? tokenStorage;

  const DashboardView({
    super.key,
    this.onBack,
    this.viewModel,
    this.client,
    this.tokenStorage,
  });

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

/// Backward compatibility alias for DashboardView
typedef DashboardPage = DashboardView;

class _DashboardViewState extends State<DashboardView> {
  late final DashboardViewModel _viewModel;
  late final bool _internalVm;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _internalVm = false;
    } else {
      _viewModel = DashboardViewModel(
        client: widget.client,
        tokenStorage: widget.tokenStorage,
      );
      _internalVm = true;
    }
    _viewModel.fetchDashboard();
  }

  @override
  void dispose() {
    if (_internalVm) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _showCustomDateRangePicker() async {
    final now = DateTime.now();
    final initialRange =
        _viewModel.customDateRange ??
        DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);

    final picked = await showCustomDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      _viewModel.setCustomDateRange(picked.start, picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        child: AnimatedBuilder(
          animation: _viewModel,
          builder: (context, _) {
            return RefreshIndicator(
              onRefresh: () => _viewModel.fetchDashboard(),
              color: AppColors.whatsappGreen,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Time Range Filter Bar with Custom Date Range Picker
                    DashboardTimeFilterBar(
                      filters: _viewModel.availableFilters,
                      selectedFilter: _viewModel.selectedFilter,
                      onFilterSelected: (newFilter) {
                        if (newFilter.startsWith('Custom') ||
                            newFilter == 'Custom') {
                          _showCustomDateRangePicker();
                        } else {
                          _viewModel.selectFilter(newFilter);
                        }
                      },
                      onCustomTap: _showCustomDateRangePicker,
                    ),
                    const SizedBox(height: 16),

                    // 2. Metrics Content: Skeleton / Error / Live Cards
                    if (_viewModel.isLoading &&
                        _viewModel.dashboardData == null)
                      const DashboardMetricsSkeletonGrid()
                    else if (_viewModel.errorMessage != null &&
                        _viewModel.dashboardData == null)
                      _buildErrorState(isDark)
                    else ...[
                      // Row 1: New Booking & Pending
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: MetricStatCard(
                                data: _viewModel.newBookingMetric,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MetricStatCard(
                                data: _viewModel.pendingMetric,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Row 2: Completed & Scheduled
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: MetricStatCard(
                                data: _viewModel.completedMetric,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: MetricStatCard(
                                data: _viewModel.scheduledMetric,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    final textColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final cardBg = isDark
        ? const Color.fromARGB(255, 36, 36, 41)
        : const Color(0xFFFEE2E2);
    final borderColor = isDark
        ? const Color(0xFF3F3F46)
        : const Color(0xFFFECACA);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFEF4444),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            _viewModel.errorMessage ?? 'Failed to load dashboard metrics',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _viewModel.retry(),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.whatsappGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
