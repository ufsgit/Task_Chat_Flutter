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

/// Available branch managers for assignment by Coordinator (fallback).
const List<String> availableBranchManagers = [
  'Sarah Jenkins',
  'Ramesh Kumar',
  'Alex Morgan',
  'Priya Sharma',
];

/// Data model representing a Branch Head user returned by GET /api/users?role=branch_head.
class BranchHeadUser {
  final int id;
  final String name;
  final String username;
  final String role;
  final int? roleId;
  final String? phone;
  final String? email;
  final int? districtId;
  final String? districtName;

  const BranchHeadUser({
    required this.id,
    required this.name,
    required this.username,
    this.role = 'branch_head',
    this.roleId,
    this.phone,
    this.email,
    this.districtId,
    this.districtName,
  });

  factory BranchHeadUser.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString() ?? '';
    final rawUsername = json['username']?.toString() ?? '';
    final displayName = rawName.trim().isNotEmpty
        ? rawName.trim()
        : (rawUsername.trim().isNotEmpty ? rawUsername.trim() : 'Branch Manager');

    return BranchHeadUser(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: displayName,
      username: rawUsername,
      role: json['role']?.toString() ?? 'branch_head',
      roleId: json['roleId'] as int? ?? json['role_id'] as int?,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      districtId: json['districtId'] as int? ?? json['district_id'] as int?,
      districtName: json['districtName']?.toString() ?? json['district_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'role': role,
    if (roleId != null) 'roleId': roleId,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (districtId != null) 'districtId': districtId,
    if (districtName != null) 'districtName': districtName,
  };
}

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
  })  : client = client ?? AuthenticatedClient(),
        tokenStorage = tokenStorage ?? TokenStorage();

  /// Fetches status filter chips from GET /api/status.
  Future<List<StatusChipModel>> fetchStatusChips() async {
    return StatusChipsService(
      client: client,
      tokenStorage: tokenStorage,
    ).fetchStatusChips();
  }

  /// Fetches branch head managers from backend GET /api/users?role=branch_head.
  Future<List<BranchHeadUser>> fetchBranchManagers() async {
    final isTest = TokenStorage.isTestEnvironment;
    String? token;
    try {
      token = await tokenStorage
          .getToken()
          .timeout(isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 5));
    } catch (_) {}

    try {
      final response = await client.get(
        Uri.parse(ApiConfig.branch_head_listing),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final dynamic rawList = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded['users'] ?? decoded['items'])
            : (decoded is List ? decoded : []);

        if (rawList is List) {
          return rawList
              .map((item) => BranchHeadUser.fromJson(item as Map<String, dynamic>))
              .where((u) => u.name.isNotEmpty)
              .toList();
        }
      }
    } catch (_) {}
    return [];
  }

  /// Submits the updated status to the backend POST /api/status endpoint.
  Future<bool> submitStatusUpdate({
    required CustomerDetailsData customer,
    required String status,
    required String scheduleDate,
    required String notes,
    required String branchManager,
    int? branchManagerId,
    String? branchManagerName,
    int? districtId,
    String? districtName,
    List<String>? documents,
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

    int effectiveCreatedBy = branchManagerId ?? 0;
    String effectiveCreatedByName = branchManagerName ?? branchManager;
    int? effectiveDistrictId = districtId;
    String? effectiveDistrictName = districtName;

    if ((effectiveCreatedBy == 0 || effectiveDistrictId == null || effectiveDistrictName == null) &&
        branchManager.isNotEmpty) {
      final managers = await fetchBranchManagers();
      final match = managers
          .where((m) =>
              m.name.toLowerCase().trim() == branchManager.toLowerCase().trim() ||
              m.username.toLowerCase().trim() == branchManager.toLowerCase().trim() ||
              (branchManagerId != null && m.id == branchManagerId))
          .firstOrNull;
      if (match != null) {
        if (effectiveCreatedBy == 0) {
          effectiveCreatedBy = match.id;
          effectiveCreatedByName = match.name;
        }
        effectiveDistrictId ??= match.districtId;
        effectiveDistrictName ??= match.districtName;
      }
    }

    if (effectiveCreatedBy == 0) {
      effectiveCreatedBy = user?.id ?? 0;
      effectiveCreatedByName = (user?.name != null && user!.name.isNotEmpty)
          ? user.name
          : (user?.username.isNotEmpty == true ? user!.username : 'Coordinator');
    }

    effectiveDistrictId ??= user?.districtId;
    effectiveDistrictName ??= user?.districtName;

    final requestPayload = StatusUpdateRequest(
      clientId: int.tryParse(customer.id) ?? 1,
      clientName: customer.name,
      status: status,
      scheduleDate: scheduleDate,
      notes: notes.trim(),
      createdBy: effectiveCreatedBy,
      createdByName: effectiveCreatedByName,
      branchManager: branchManager,
      branchManagerId: effectiveCreatedBy,
      branchManagerName: effectiveCreatedByName,
      districtId: effectiveDistrictId,
      districtName: effectiveDistrictName,
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
      if (documents != null && !listEquals(documents, customer.documents)) {
        try {
          final bookingUri = Uri.parse('${ApiConfig.bookings}/${customer.id}');
          await client.put(
            bookingUri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
            },
            body: jsonEncode({'documents': documents}),
          ).timeout(const Duration(seconds: 10));
        } catch (_) {}
      }

      updateChatItemStatus(
        customerName: customer.name,
        newStatus: status,
        newDate: scheduleDate,
      );
      return true;
    }
    return false;
  }
}
