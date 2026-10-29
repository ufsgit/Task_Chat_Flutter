import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/circular_back_button.dart';
import '../widgets/attention_efficiency_card.dart';
import '../widgets/daily_average_card.dart';
import '../widgets/staff_performance_card.dart';
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
        final data = _viewModel.data;

        return RefreshIndicator(
          color: AppColors.primaryGreen,
          onRefresh: _viewModel.refreshReport,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 100.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Attention & Efficiency Card
                AttentionEfficiencyCard(data: data.attentionEfficiency),
                const SizedBox(height: 16),

                // 2. Staff Performance Card
                StaffPerformanceCard(staffList: data.staffList),
                const SizedBox(height: 16),

                // 3. Daily Average Summary Card with Stacked Bar Chart
                DailyAverageCard(summary: data.dailyAverage),
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
          child: Center(
            child: CircularBackButton(
              onBack: _handleBack,
            ),
          ),
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
      body: SafeArea(
        child: _buildBody(context, isDark),
      ),
    );
  }
}
