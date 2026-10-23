import 'package:flutter/material.dart';
import '../core/widgets/circular_back_button.dart';
import '../core/theme.dart';
import 'task_report_data.dart';
import 'widgets/attention_efficiency_card.dart';
import 'widgets/daily_average_card.dart';
import 'widgets/staff_performance_card.dart';

/// Task Report screen matching the design.
/// Data is cleanly decoupled in `task_report_data.dart`,
/// and UI components are modularized in `widgets/`.
class TaskReportPage extends StatefulWidget {
  final TaskReportData? initialData;
  final VoidCallback? onBack;

  const TaskReportPage({
    super.key,
    this.initialData,
    this.onBack,
  });

  @override
  State<TaskReportPage> createState() => _TaskReportPageState();
}

class _TaskReportPageState extends State<TaskReportPage> {
  late TaskReportData _data;

  @override
  void initState() {
    super.initState();
    _data = widget.initialData ?? defaultTaskReportData;
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

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
            color: isDark ? AppDarkColors.whatsappGreen : const Color(0xFF005C4B),
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),

              // 1. Date Range Header Bar ("This Week (Nov 10 – Nov 16)" + Chevron)
              _buildDateSelectorBar(context, isDark),

              const SizedBox(height: 14),

              // 2. Daily Average & Stacked Bar Chart Card
              DailyAverageCard(summary: _data.dailyAverage),

              const SizedBox(height: 18),

              // 3. Attention & Efficiency Card
              AttentionEfficiencyCard(data: _data.attentionEfficiency),

              const SizedBox(height: 18),

              // 4. Staff Performance Card
              StaffPerformanceCard(
                staffList: _data.staffList,
                onShowAllTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Showing all staff performance'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                onStaffTap: (staff) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Selected: ${staff.name}'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),

              // Bottom padding so content is never obscured by floating bottom bar or screen edge
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelectorBar(BuildContext context, bool isDark) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
            ),
            children: [
              TextSpan(
                text: _data.weekTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' (${_data.dateRange})',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppDarkColors.textSubtitle : AppColors.textSubtitle,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Date range picker'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isDark ? AppDarkColors.surfaceCard : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? AppDarkColors.border : const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? AppDarkColors.textSubtitle : AppColors.textSubtitle,
            ),
          ),
        ),
      ],
    );
  }
}
