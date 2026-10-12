/// Separated data models and visibility rules for Update Status.
/// Keeps form state and business logic decoupled from the UI.
const List<String> availableStatusOptions = [
  'Completed',
  'Scheduled',
  'Cancelled',
];

/// Status options available to Super Admin
const List<String> availableSuperAdminStatusOptions = [
  'Completed',
  'Scheduled',
  'Cancelled',
];

/// Available branch managers for assignment
const List<String> availableBranchManagers = [
  'Sarah Jenkins',
  'Ramesh Kumar',
  'Alex Morgan',
  'Priya Sharma',
];

/// Helper determining which fields are visible according to the selected status:
/// - Completed: only Schedule (Calendar) is shown
/// - Cancelled: only Notes is shown
/// - Scheduled: all fields (Notes, Schedule, Location, Group) are shown
class UpdateStatusVisibility {
  final String status;

  const UpdateStatusVisibility(this.status);

  bool get showSchedule =>
      status.toLowerCase() == 'completed' ||
      status.toLowerCase() == 'scheduled';

  bool get showNotes =>
      status.toLowerCase() == 'cancelled' ||
      status.toLowerCase() == 'scheduled';

  bool get showLocation => status.toLowerCase() == 'scheduled';

  bool get showGroup => status.toLowerCase() == 'scheduled';
}

/// Initial or default form data for updating a customer's status.
class UpdateStatusFormData {
  final String defaultStatus;
  final String defaultNotes;
  final String defaultScheduleDate;
  final String defaultLocation;
  final String defaultGroup;

  const UpdateStatusFormData({
    this.defaultStatus = 'Completed',
    this.defaultNotes =
        '“Use Omron digital arm monitor. Rest seated 5 minutes beforehand. Record both systolic and diastolic numbers carefully.”',
    this.defaultScheduleDate = '10/24/2024',
    this.defaultLocation = 'Home',
    this.defaultGroup = 'Personal Care',
  });
}

const UpdateStatusFormData defaultUpdateStatusFormData = UpdateStatusFormData();

/// Default form data for Super Admin Update Status
class SuperAdminUpdateStatusFormData {
  final String defaultStatus;
  final String defaultNotes;
  final String defaultScheduleDate;
  final String defaultLocation;
  final String defaultBranchManager;
  final String defaultGroup;

  const SuperAdminUpdateStatusFormData({
    this.defaultStatus = 'Completed',
    this.defaultNotes =
        '“Use Omron digital arm monitor. Rest seated 5 minutes beforehand. Record both systolic and diastolic numbers carefully.”',
    this.defaultScheduleDate = '10/24/2024',
    this.defaultLocation = 'Home',
    this.defaultBranchManager = 'Sarah Jenkins',
    this.defaultGroup = 'Personal Care',
  });
}

const SuperAdminUpdateStatusFormData defaultSuperAdminUpdateStatusFormData =
    SuperAdminUpdateStatusFormData();

