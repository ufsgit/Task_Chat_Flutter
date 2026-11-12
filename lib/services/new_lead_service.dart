import 'package:flutter/foundation.dart';
import '../Coordinator/coordinator_view_model.dart';
import '../today/today_view_model.dart';

/// Centralized service to coordinate lead list refreshes across active ViewModels.
class NewLeadService {
  static final NewLeadService instance = NewLeadService._internal();
  NewLeadService._internal();

  final List<VoidCallback> _onRefreshCallbacks = [];

  void addRefreshListener(VoidCallback callback) {
    _onRefreshCallbacks.add(callback);
  }

  void removeRefreshListener(VoidCallback callback) {
    _onRefreshCallbacks.remove(callback);
  }

  /// Dispatches a refresh across TodayViewModel, CoordinatorViewModel, and any registered listeners.
  void triggerRefresh() {
    TodayViewModel.currentSession?.refreshBookings();
    CoordinatorViewModel.currentSession?.fetchBookings();
    for (final cb in List.of(_onRefreshCallbacks)) {
      try {
        cb();
      } catch (_) {}
    }
  }
}
