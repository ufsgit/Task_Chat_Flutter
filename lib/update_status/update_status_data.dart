// Separated data models and visibility rules for Update Status.
// Keeps form state and business logic decoupled from the UI.

/// Returns the status options available to the user based on whether
/// the customer has been scheduled at least once.
/// "Completed" only shows after the customer has been scheduled once.
List<String> getAvailableStatusOptions({required bool hasBeenScheduled}) {
  if (hasBeenScheduled) {
    return const ['Completed', 'Scheduled', 'Cancelled'];
  } else {
    return const ['Scheduled', 'Cancelled'];
  }
}

const List<String> availableStatusOptions = [
  'Completed',
  'Scheduled',
  'Cancelled',
];

/// Status options available to Coordinator (formerly Super Admin)
const List<String> availableCoordinatorStatusOptions = [
  'Completed',
  'Scheduled',
  'Cancelled',
];

/// Backward compatibility alias for Coordinator status options
const List<String> availableSuperAdminStatusOptions =
    availableCoordinatorStatusOptions;

/// Available branch managers for assignment
const List<String> availableBranchManagers = [
  'Sarah Jenkins',
  'Ramesh Kumar',
  'Alex Morgan',
  'Priya Sharma',
];

/// Helper determining which fields are visible:
/// Per requirements, location field is removed and all three statuses
/// (Completed, Scheduled, Cancelled) use the same: Notes and Calendar only.
class UpdateStatusVisibility {
  final String status;

  const UpdateStatusVisibility(this.status);

  /// Schedule (Calendar) is shown for Completed and Scheduled, but removed for Cancelled
  bool get showSchedule => status.toLowerCase() != 'cancelled';

  /// All statuses use Notes
  bool get showNotes => true;

  /// Location field has been removed
  bool get showLocation => false;

  bool get showGroup => false;

  /// Coordinator / Branch Manager assignment when scheduled
  bool get showBranchManager => status.toLowerCase() == 'scheduled';
}

/// Initial or default form data for updating a customer's status.
class UpdateStatusFormData {
  final String defaultStatus;
  final String defaultNotes;
  final String defaultScheduleDate;

  const UpdateStatusFormData({
    this.defaultStatus = 'Scheduled',
    this.defaultNotes = '',
    this.defaultScheduleDate = '10/24/2024',
  });
}

const UpdateStatusFormData defaultUpdateStatusFormData = UpdateStatusFormData();

/// Default form data for Coordinator Update Status
class CoordinatorUpdateStatusFormData {
  final String defaultStatus;
  final String defaultNotes;
  final String defaultScheduleDate;
  final String defaultBranchManager;

  const CoordinatorUpdateStatusFormData({
    this.defaultStatus = 'Scheduled',
    this.defaultNotes = '',
    this.defaultScheduleDate = '10/24/2024',
    this.defaultBranchManager = 'Sarah Jenkins',
  });
}

/// Backward compatibility alias
typedef SuperAdminUpdateStatusFormData = CoordinatorUpdateStatusFormData;

const CoordinatorUpdateStatusFormData defaultCoordinatorUpdateStatusFormData =
    CoordinatorUpdateStatusFormData();

/// Backward compatibility alias
const CoordinatorUpdateStatusFormData defaultSuperAdminUpdateStatusFormData =
    defaultCoordinatorUpdateStatusFormData;

