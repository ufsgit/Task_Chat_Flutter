/// Result object returned when a status update is saved successfully from
/// either CoordinatorUpdateStatusView or BranchManagerUpdateStatusView.
class StatusUpdateResult {
  final String status;
  final String scheduleDate;
  final String notes;
  final String staffNotes;
  final List<String> documents;
  final String? branchManager;

  const StatusUpdateResult({
    required this.status,
    required this.scheduleDate,
    required this.notes,
    String? staffNotes,
    required this.documents,
    this.branchManager,
  }) : staffNotes = staffNotes ?? notes;

  @override
  String toString() => status;
}
