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
  DashboardModel? _dashboardData;

  DashboardViewModel({
    DashboardService? service,
    http.Client? client,
    TokenStorage? tokenStorage,
    DashboardPeriod initialPeriod = DashboardPeriod.currentMonth,
  }) : _selectedPeriod = initialPeriod,
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
  String get selectedFilter => _selectedPeriod.label;
  DashboardModel? get dashboardData => _dashboardData;

  /// Available filter chip labels.
  List<String> get availableFilters => [
    DashboardPeriod.currentMonth.label,
    DashboardPeriod.last30Days.label,
    DashboardPeriod.allTime.label,
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
    bool force = false,
  }) async {
    if (_isLoading && !force) return;
    final targetPeriod = period ?? _selectedPeriod;
    _selectedPeriod = targetPeriod;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _service.fetchDashboard(period: targetPeriod);
      _dashboardData = result;
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Changes the active period and immediately refetches data.
  void selectFilter(String label) {
    final period = DashboardPeriod.fromLabel(label);
    if (period == _selectedPeriod && _dashboardData != null) return;
    _selectedPeriod = period;
    fetchDashboard(period: period);
  }

  /// Retries the current fetch operation.
  void retry() {
    fetchDashboard(period: _selectedPeriod);
  }

  @override
  void dispose() {
    if (_isInternalClient && _client != null) {
      _client.close();
    }
    super.dispose();
  }
}
