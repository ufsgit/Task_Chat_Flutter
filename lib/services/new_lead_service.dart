import 'package:flutter/foundation.dart';
import '../Coordinator/coordinator_view_model.dart';
import '../today/today_view_model.dart';

/// Event payload containing details about a newly added lead or booking.
class NewLeadEvent {
  final String? leadName;
  final String? location;
  final dynamic bookingId;
  final DateTime timestamp;

  NewLeadEvent({
    this.leadName,
    this.location,
    this.bookingId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Formatted subtitle for the in-app banner.
  String get displaySubtitle {
    final parts = <String>[];
    if (leadName != null && leadName!.trim().isNotEmpty) {
      parts.add(leadName!.trim());
    }
    if (location != null && location!.trim().isNotEmpty) {
      parts.add(location!.trim());
    }
    if (parts.isNotEmpty) {
      return parts.join(' • ');
    }
    return 'Tap Refresh to view the latest leads';
  }
}

/// Centralized service to manage in-app "New Lead Added" banner alerts and list refreshes.
class NewLeadService {
  static final NewLeadService instance = NewLeadService._internal();
  NewLeadService._internal();

  /// Currently active new lead banner event, or null if dismissed.
  final ValueNotifier<NewLeadEvent?> currentEvent =
      ValueNotifier<NewLeadEvent?>(null);

  final List<VoidCallback> _onRefreshCallbacks = [];

  void addRefreshListener(VoidCallback callback) {
    _onRefreshCallbacks.add(callback);
  }

  void removeRefreshListener(VoidCallback callback) {
    _onRefreshCallbacks.remove(callback);
  }

  /// Triggers the in-app banner to alert that a new lead has been added,
  /// and automatically triggers a refresh on the active session view models.
  void notifyNewLead({
    String? leadName,
    String? location,
    dynamic bookingId,
    bool autoRefresh = true,
  }) {
    currentEvent.value = NewLeadEvent(
      leadName: leadName,
      location: location,
      bookingId: bookingId,
    );

    if (autoRefresh) {
      triggerRefresh();
    }
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

  /// Dismisses the active in-app banner.
  void dismiss() {
    currentEvent.value = null;
  }
}
