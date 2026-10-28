import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login_page/token_storage.dart';
import 'dashboard_model.dart';

/// ViewModel managing state, API calls, and business logic for the Dashboard screen.
class DashboardViewModel extends ChangeNotifier {
  final DashboardService _service;
  final http.Client? _client;
  final bool _isInternalClient;

  bool _isLoading = false;
  String? _errorMessage;
  DashboardPeriod _selectedPeriod = DashboardPeriod.currentMonth;
  DateTimeRange? _customDateRange;
  DashboardModel? _dashboardData;

  DashboardViewModel({
    DashboardService? service,
    http.Client? client,
    TokenStorage? tokenStorage,
    DashboardPeriod initialPeriod = DashboardPeriod.currentMonth,
    DateTimeRange? initialDateRange,
  }) : _selectedPeriod = initialPeriod,
       _customDateRange = initialDateRange,
       _client = client,
       _isInternalClient = client == null && service == null,
       _service =
           service ??
           DashboardService(client: client, tokenStorage: tokenStorage);

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DashboardPeriod get selectedPeriod => _selectedPeriod;
  DateTimeRange? get customDateRange => _customDateRange;
  DateTime? get customStartDate => _customDateRange?.start;
  DateTime? get customEndDate => _customDateRange?.end;

  /// Formatted custom date label for display on the chip.
  String get customDateLabel {
    if (_customDateRange != null) {
      final s = _customDateRange!.start;
      final e = _customDateRange!.end;
      final startStr =
          '${s.day.toString().padLeft(2, '0')}/${s.month.toString().padLeft(2, '0')}';
      final endStr =
          '${e.day.toString().padLeft(2, '0')}/${e.month.toString().padLeft(2, '0')}';
      return 'Custom ($startStr - $endStr)';
    }
    return 'Custom';
  }

  String get selectedFilter {
    if (_selectedPeriod == DashboardPeriod.custom) {
      return customDateLabel;
    }
    return _selectedPeriod.label;
  }

  DashboardModel? get dashboardData => _dashboardData;

  /// Available filter chip labels.
  List<String> get availableFilters => [
    DashboardPeriod.currentMonth.label,
    DashboardPeriod.last30Days.label,
    DashboardPeriod.allTime.label,
    if (_selectedPeriod == DashboardPeriod.custom)
      customDateLabel
    else
      'Custom',
  ];

  /// Dynamic MetricCardData for New Booking
  MetricCardData get newBookingMetric =>
      (_dashboardData ?? const DashboardModel()).toNewBookingCard(
        period: _selectedPeriod,
      );

  /// Dynamic MetricCardData for Pending
  MetricCardData get pendingMetric => (_dashboardData ?? const DashboardModel())
      .toPendingCard(period: _selectedPeriod);

  /// Dynamic MetricCardData for Completed
  MetricCardData get completedMetric =>
      (_dashboardData ?? const DashboardModel()).toCompletedCard(
        period: _selectedPeriod,
      );

  /// Dynamic MetricCardData for Scheduled
  MetricCardData get scheduledMetric =>
      (_dashboardData ?? const DashboardModel()).toScheduledCard(
        period: _selectedPeriod,
      );

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Fetches dashboard metrics from the backend API for the active or specified period.
  Future<void> fetchDashboard({
    DashboardPeriod? period,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool force = false,
  }) async {
    if (_isLoading && !force) return;
    final targetPeriod = period ?? _selectedPeriod;
    _selectedPeriod = targetPeriod;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final effectiveFrom =
          dateFrom ??
          (targetPeriod == DashboardPeriod.custom
              ? _customDateRange?.start
              : null);
      final effectiveTo =
          dateTo ??
          (targetPeriod == DashboardPeriod.custom
              ? _customDateRange?.end
              : null);
      final result = await _service.fetchDashboard(
        period: targetPeriod,
        dateFrom: effectiveFrom,
        dateTo: effectiveTo,
      );
      _dashboardData = result;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets a custom date range and immediately fetches dashboard metrics.
  void setCustomDateRange(DateTime start, DateTime end) {
    _customDateRange = DateTimeRange(start: start, end: end);
    _selectedPeriod = DashboardPeriod.custom;
    fetchDashboard(
      period: DashboardPeriod.custom,
      dateFrom: start,
      dateTo: end,
      force: true,
    );
  }

  /// Changes the active period and immediately refetches data.
  void selectFilter(String label) {
    final period = DashboardPeriod.fromLabel(label);
    if (period == _selectedPeriod &&
        _dashboardData != null &&
        period != DashboardPeriod.custom) {
      return;
    }
    _selectedPeriod = period;
    fetchDashboard(period: period);
  }

  /// Retries the current fetch operation.
  void retry() {
    fetchDashboard(
      period: _selectedPeriod,
      dateFrom:
          _selectedPeriod == DashboardPeriod.custom
              ? _customDateRange?.start
              : null,
      dateTo:
          _selectedPeriod == DashboardPeriod.custom
              ? _customDateRange?.end
              : null,
      force: true,
    );
  }

  @override
  void dispose() {
    if (_isInternalClient && _client != null) {
      _client.close();
    }
    super.dispose();
  }
}
