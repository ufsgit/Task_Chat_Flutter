import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../api/api.dart';
import '../../api/authenticated_client.dart';
import '../../customer_details/customer_details_model.dart';
import '../../login_page/login_model.dart';
import '../../login_page/token_storage.dart';
import '../../settings/settings_model.dart';
import '../../today/today_view_model.dart';
import '../models/status_chip_model.dart';
import '../services/status_chips_service.dart';

/// Available status options for Branch Manager.
const List<String> availableStatusOptions = [
  'Completed',
  'Scheduled',
  'Cancelled',
  'New',
];

/// Returns the status options available based on whether the customer has been scheduled.
List<String> getAvailableStatusOptions({required bool hasBeenScheduled}) {
  if (hasBeenScheduled) {
    return const ['Completed', 'Scheduled', 'Cancelled'];
  } else {
    return const ['New', 'Scheduled', 'Cancelled'];
  }
}

/// Formats current date as MM/DD/YYYY to match scheduleDate format.
String formatCurrentDate() {
  final now = DateTime.now();
  final m = now.month.toString().padLeft(2, '0');
  final d = now.day.toString().padLeft(2, '0');
  return '$m/$d/${now.year}';
}

/// Helper determining UI field visibility rules for status updates.
class UpdateStatusVisibility {
  final String status;

  const UpdateStatusVisibility(this.status);

  /// Schedule (Calendar) is shown for Scheduled, hidden for Completed and Cancelled.
  bool get showSchedule =>
      status.toLowerCase() != 'cancelled' &&
      status.toLowerCase() != 'completed';

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
  final String? branchManager;
  final int? branchManagerId;
  final String? branchManagerName;
  final int? districtId;
  final String? districtName;

  const StatusUpdateRequest({
    required this.clientId,
    required this.clientName,
    required this.status,
    required this.scheduleDate,
    required this.notes,
    required this.createdBy,
    required this.createdByName,
    this.branchManager,
    this.branchManagerId,
    this.branchManagerName,
    this.districtId,
    this.districtName,
  });

  Map<String, dynamic> toJson() => {
    'clientId': clientId,
    'clientName': clientName,
    'status': status,
    'scheduleDate': scheduleDate,
    'notes': notes,
    'createdBy': createdBy,
    'createdByName': createdByName,
    if (branchManager != null && branchManager!.isNotEmpty)
      'branchManager': branchManager,
    if (branchManagerId != null) 'branchManagerId': branchManagerId,
    if (branchManagerName != null && branchManagerName!.isNotEmpty)
      'branchManagerName': branchManagerName,
    if (districtId != null && districtId! > 0) 'districtId': districtId,
    if (districtName != null && districtName!.isNotEmpty)
      'districtName': districtName,
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
      branchManager: json['branchManager']?.toString(),
      branchManagerId:
          json['branchManagerId'] as int? ??
          int.tryParse(json['branchManagerId']?.toString() ?? ''),
      branchManagerName: json['branchManagerName']?.toString(),
      districtId:
          json['districtId'] as int? ??
          int.tryParse(json['districtId']?.toString() ?? ''),
      districtName: json['districtName']?.toString(),
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
  }) : client = client ?? AuthenticatedClient(),
       tokenStorage = tokenStorage ?? TokenStorage();

  /// Fetches status filter chips from GET /api/status.
  Future<List<StatusChipModel>> fetchStatusChips() async {
    return StatusChipsService(
      client: client,
      tokenStorage: tokenStorage,
    ).fetchStatusChips();
  }

  /// Submits the updated status to the backend POST /api/status endpoint.
  Future<bool> submitStatusUpdate({
    required CustomerDetailsData customer,
    required String status,
    required String scheduleDate,
    required String notes,
    List<String>? documents,
  }) async {
    final isTest = TokenStorage.isTestEnvironment;
    String? token;
    try {
      token = await tokenStorage.getToken().timeout(
        isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 5),
      );
    } catch (_) {}

    UserModel? user;
    try {
      user = await UserProfileData.loadUser().timeout(
        isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 2),
      );
    } catch (_) {}

    final isCompleted = status.toLowerCase() == 'completed';
    final effectiveDate = isCompleted
        ? formatCurrentDate()
        : (scheduleDate.trim().isNotEmpty ? scheduleDate : formatCurrentDate());

    final requestPayload = StatusUpdateRequest(
      clientId: int.tryParse(customer.id) ?? 1,
      clientName: customer.name,
      status: status,
      scheduleDate: effectiveDate,
      notes: notes.trim(),
      createdBy: user?.id ?? 0,
      createdByName: (user?.name != null && user!.name.isNotEmpty)
          ? user.name
          : (user?.username.isNotEmpty == true
                ? user!.username
                : 'Branch Manager'),
    );

    final response = await client
        .post(
          Uri.parse(ApiConfig.statusUpdate),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (token != null && token.isNotEmpty)
              'authorization': token.startsWith('Bearer ')
                  ? token
                  : 'Bearer $token',
          },
          body: jsonEncode(requestPayload.toJson()),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (documents != null && !listEquals(documents, customer.documents)) {
        try {
          final bookingUri = Uri.parse('${ApiConfig.bookings}/${customer.id}');
          await client
              .put(
                bookingUri,
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                  if (token != null && token.isNotEmpty)
                    'authorization': token.startsWith('Bearer ')
                        ? token
                        : 'Bearer $token',
                },
                body: jsonEncode({'documents': documents}),
              )
              .timeout(const Duration(seconds: 10));
        } catch (_) {}
      }

      updateChatItemStatus(
        customerName: customer.name,
        newStatus: status,
        newDate: effectiveDate,
      );
      return true;
    }
    return false;
  }
}
