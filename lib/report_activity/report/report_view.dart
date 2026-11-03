import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/circular_back_button.dart';
import '../widgets/report_date_range_bar.dart';
import '../widgets/weekly_activity_graph_card.dart';

import 'report_view_model.dart';

/// Report section / page displaying performance metrics, daily average, and staff tracking.
class ReportView extends StatefulWidget {
  final ReportViewModel? viewModel;
  final VoidCallback? onBack;
  final bool embedSection;

  const ReportView({
    super.key,
    this.viewModel,
    this.onBack,
    this.embedSection = false,
  });

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  late final ReportViewModel _viewModel;
  late final bool _isLocalViewModel;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _isLocalViewModel = false;
    } else {
      _viewModel = ReportViewModel();
      _isLocalViewModel = true;
    }
    _viewModel.fetchGraphReport();
  }

  @override
  void dispose() {
    if (_isLocalViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: _viewModel.refreshReport,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Date Range Filter Bar (From Date & To Date) - FIRST
                ReportDateRangeBar(
                  dateFrom: _viewModel.dateFrom,
                  dateTo: _viewModel.dateTo,
                  onDateRangeChanged: (from, to) {
                    _viewModel.setDateRange(from: from, to: to);
                  },
                  onClear: () {
                    _viewModel.clearDateRange();
                  },
                ),
                const SizedBox(height: 14),

                // 2. Weekly Activity Graph from /api/reports/bookings
                WeeklyActivityGraphCard(
                  graphData: _viewModel.graphData,
                  isLoading: _viewModel.isGraphLoading,
                  errorMessage: _viewModel.graphErrorMessage,
                  dateFrom: _viewModel.dateFrom,
                  dateTo: _viewModel.dateTo,
                  onRefresh: () => _viewModel.fetchGraphReport(force: true),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    if (widget.embedSection) {
      return _buildBody(context, isDark);
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(child: CircularBackButton(onBack: _handleBack)),
        ),
        titleSpacing: 8,
        title: Text(
          'Task Report',
          style: TextStyle(
            color: isDark ? AppDarkColors.whatsappGreen : AppColors.brandGreen,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody(context, isDark)),
    );
  }
}
