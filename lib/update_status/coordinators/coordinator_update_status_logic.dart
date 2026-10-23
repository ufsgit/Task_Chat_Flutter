import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api/api.dart';
import '../../customer_details/customer_details_model.dart';
import '../../login_page/login_model.dart';
import '../../login_page/token_storage.dart';
import '../../settings/settings_model.dart';
import '../../today/today_view_model.dart';
import '../branch_manager/branch_manager_update_status_logic.dart';

/// Available status options for Coordinator.
const List<String> availableCoordinatorStatusOptions = [
  'Completed',
  'Scheduled',
  'Cancelled',
];

/// Backward compatibility alias
const List<String> availableSuperAdminStatusOptions =
    availableCoordinatorStatusOptions;

/// Available branch managers for assignment by Coordinator.
const List<String> availableBranchManagers = [
  'Sarah Jenkins',
  'Ramesh Kumar',
  'Alex Morgan',
  'Priya Sharma',
];

/// Helper determining UI field visibility rules for Coordinator status updates.
class CoordinatorUpdateStatusVisibility {
  final String status;

  const CoordinatorUpdateStatusVisibility(this.status);

  /// Schedule (Calendar) is shown for Completed and Scheduled, hidden for Cancelled.
  bool get showSchedule => status.toLowerCase() != 'cancelled';

  /// All statuses use Notes.
  bool get showNotes => true;

  /// Branch Manager assignment field shown when scheduled.
  bool get showBranchManager => status.toLowerCase() == 'scheduled';
}

/// Business logic and API persistence for Coordinator status updates.
class CoordinatorUpdateStatusLogic {
  final http.Client client;
  final TokenStorage tokenStorage;

  CoordinatorUpdateStatusLogic({
    http.Client? client,
    TokenStorage? tokenStorage,
  })  : client = client ?? http.Client(),
        tokenStorage = tokenStorage ?? TokenStorage();

  /// Submits the updated status to the backend POST /api/status endpoint.
  Future<bool> submitStatusUpdate({
    required CustomerDetailsData customer,
    required String status,
    required String scheduleDate,
    required String notes,
    required String branchManager,
  }) async {
    final isTest = TokenStorage.isTestEnvironment;
    String? token;
    try {
      token = await tokenStorage
          .getToken()
          .timeout(isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 5));
    } catch (_) {}

    UserModel? user;
    try {
      user = await UserProfileData.loadUser()
          .timeout(isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 2));
    } catch (_) {}

    final requestPayload = StatusUpdateRequest(
      clientId: int.tryParse(customer.id) ?? 1,
      clientName: customer.name,
      status: status,
      scheduleDate: scheduleDate,
      notes: notes.trim(),
      createdBy: user?.id ?? 0,
      createdByName: (user?.name != null && user!.name.isNotEmpty)
          ? user.name
          : (user?.username.isNotEmpty == true ? user!.username : 'Coordinator'),
    );

    final response = await client.post(
      Uri.parse(ApiConfig.statusUpdate),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
      },
      body: jsonEncode(requestPayload.toJson()),
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      updateChatItemStatus(
        customerName: customer.name,
        newStatus: status,
      );
      return true;
    }
    return false;
  }
}
