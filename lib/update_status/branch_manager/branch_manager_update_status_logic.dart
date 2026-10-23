import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api/api.dart';
import '../../customer_details/customer_details_model.dart';
import '../../login_page/login_model.dart';
import '../../login_page/token_storage.dart';
import '../../settings/settings_model.dart';
import '../../today/today_view_model.dart';

/// Available status options for Branch Manager.
const List<String> availableStatusOptions = [
  'Completed',
  'Scheduled',
  'Cancelled',
];

/// Returns the status options available based on whether the customer has been scheduled.
List<String> getAvailableStatusOptions({required bool hasBeenScheduled}) {
  if (hasBeenScheduled) {
    return const ['Completed', 'Scheduled', 'Cancelled'];
  } else {
    return const ['Scheduled', 'Cancelled'];
  }
}

/// Helper determining UI field visibility rules for status updates.
class UpdateStatusVisibility {
  final String status;

  const UpdateStatusVisibility(this.status);

  /// Schedule (Calendar) is shown for Completed and Scheduled, hidden for Cancelled.
  bool get showSchedule => status.toLowerCase() != 'cancelled';

  /// All statuses use Notes.
  bool get showNotes => true;

  bool get showLocation => false;
  bool get showGroup => false;
  bool get showBranchManager => false;
}

/// Request payload model for POST /api/status.
class StatusUpdateRequest {
  final int clientId;
  final String clientName;
  final String status;
  final String scheduleDate;
  final String notes;
  final int createdBy;
  final String createdByName;

  const StatusUpdateRequest({
    required this.clientId,
    required this.clientName,
    required this.status,
    required this.scheduleDate,
    required this.notes,
    required this.createdBy,
    required this.createdByName,
  });

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'clientName': clientName,
    'status': status,
    'scheduleDate': scheduleDate,
    'notes': notes,
    'createdBy': createdBy,
    'createdByName': createdByName,
  };

  factory StatusUpdateRequest.fromJson(Map<String, dynamic> json) {
    return StatusUpdateRequest(
      clientId: json['clientId'] is int
          ? json['clientId'] as int
          : int.tryParse(json['clientId']?.toString() ?? '') ?? 0,
      clientName: json['clientName']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      scheduleDate: json['scheduleDate']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      createdBy: json['createdBy'] is int
          ? json['createdBy'] as int
          : int.tryParse(json['createdBy']?.toString() ?? '') ?? 0,
      createdByName: json['createdByName']?.toString() ?? '',
    );
  }
}

/// Business logic and API persistence for Branch Manager status updates.
class BranchManagerUpdateStatusLogic {
  final http.Client client;
  final TokenStorage tokenStorage;

  BranchManagerUpdateStatusLogic({
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
          : (user?.username.isNotEmpty == true ? user!.username : 'Branch Manager'),
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
