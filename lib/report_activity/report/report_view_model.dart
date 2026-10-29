import 'package:flutter/material.dart';
import 'report_model.dart';

/// ViewModel managing state, metrics, and interactions for the Report section.
class ReportViewModel extends ChangeNotifier {
  TaskReportData _data;
  bool _isLoading = false;
  String? _errorMessage;

  ReportViewModel({TaskReportData? initialData})
      : _data = initialData ?? defaultTaskReportData;

  TaskReportData get data => _data;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateData(TaskReportData newData) {
    _data = newData;
    notifyListeners();
  }

  Future<void> refreshReport() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 300));
    _isLoading = false;
    notifyListeners();
  }
}
