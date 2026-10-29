import 'package:flutter/material.dart';
import 'report/report_model.dart';
import 'report/report_view.dart';
import 'report/report_view_model.dart';

export 'report/report_model.dart';
export 'report/report_view.dart';
export 'report/report_view_model.dart';

/// Task Report page delegating to MVVM ReportView.
class TaskReportPage extends StatelessWidget {
  final TaskReportData? initialData;
  final VoidCallback? onBack;
  final ReportViewModel? viewModel;

  const TaskReportPage({
    super.key,
    this.initialData,
    this.onBack,
    this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return ReportView(
      onBack: onBack,
      viewModel: viewModel ??
          (initialData != null
              ? ReportViewModel(initialData: initialData)
              : null),
    );
  }
}
