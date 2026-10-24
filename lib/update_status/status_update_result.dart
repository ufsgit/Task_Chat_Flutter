/// Result object returned when a status update is saved successfully from
/// either CoordinatorUpdateStatusView or BranchManagerUpdateStatusView.
class StatusUpdateResult {
  final String status;
  final String scheduleDate;
  final String notes;
  final List<String> documents;
  final String? branchManager;

  const StatusUpdateResult({
    required this.status,
    required this.scheduleDate,
    required this.notes,
    required this.documents,
    this.branchManager,
  });

  @override
  String toString() => status;
}
