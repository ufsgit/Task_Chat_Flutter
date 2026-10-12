import 'package:flutter/material.dart';
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
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(
            child: GestureDetector(
              onTap: _handleBack,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: Color(0xFF005C4B),
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        titleSpacing: 8,
        title: const Text(
          'Task Report',
          style: TextStyle(
            color: Color(0xFF005C4B),
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
              _buildDateSelectorBar(context),

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

  Widget _buildDateSelectorBar(BuildContext context) {
    return Row(
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
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
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSubtitle,
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
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 0.8,
              ),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textSubtitle,
            ),
          ),
        ),
      ],
    );
  }
}
