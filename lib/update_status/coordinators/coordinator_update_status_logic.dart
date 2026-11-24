import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api/api.dart';
import '../../api/authenticated_client.dart';
import '../../customer_details/customer_details_model.dart';
import '../../login_page/login_model.dart';
import '../../login_page/token_storage.dart';
import '../../settings/settings_model.dart';
import '../models/status_chip_model.dart';
import '../services/status_chips_service.dart';
import '../services/status_update_helper.dart';
import '../branch_manager/branch_manager_update_status_logic.dart';

/// Available status options for Coordinator.
const List<String> availableCoordinatorStatusOptions = [
  'Completed',
  'Scheduled',
  'Cancelled',
];

/// Data model representing a Branch Head user returned by GET /api/users/get_branch_heads_for_status_update.
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
  final int? areaId;
  final String? areaName;
  final String? areaPincode;
  final String? displayLabel;
  final String listingLabel;

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
    this.areaId,
    this.areaName,
    this.areaPincode,
    this.displayLabel,
    String? listingLabel,
  }) : listingLabel = listingLabel ?? name;

  factory BranchHeadUser.fromJson(Map<String, dynamic> json) {
    final rawId = json['branch_head_id'] ?? json['id'];
    final parsedId = rawId is int
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    final rawName = (json['branch_head_name'] ?? json['name'])?.toString() ?? '';
    final rawUsername = json['username']?.toString() ?? '';
    final displayName = rawName.trim().isNotEmpty
        ? rawName.trim()
        : (rawUsername.trim().isNotEmpty ? rawUsername.trim() : 'Branch Manager');

    final parsedDistrictId = json['district_id'] is int
        ? json['district_id'] as int
        : (json['districtId'] is int
            ? json['districtId'] as int
            : int.tryParse((json['district_id'] ?? json['districtId'])?.toString() ?? ''));

    final parsedDistrictName = (json['district_name'] ?? json['districtName'])?.toString();

    final parsedAreaId = json['area_id'] is int
        ? json['area_id'] as int
        : (json['areaId'] is int
            ? json['areaId'] as int
            : int.tryParse((json['area_id'] ?? json['areaId'])?.toString() ?? ''));

    final parsedAreaName = (json['area_name'] ?? json['areaName'])?.toString();
    final parsedAreaPincode = (json['area_pincode'] ?? json['areaPincode'])?.toString().trim();
    final parsedDisplayLabel = (json['display_label'] ?? json['displayLabel'])?.toString().trim();

    final listing = computeListingLabel(
      displayLabel: parsedDisplayLabel,
      areaPincode: parsedAreaPincode,
      fallbackName: displayName,
    );

    return BranchHeadUser(
      id: parsedId,
      name: displayName,
      username: rawUsername.isNotEmpty ? rawUsername : displayName,
      role: json['role']?.toString() ?? 'branch_head',
      roleId: json['roleId'] as int? ?? json['role_id'] as int?,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      districtId: parsedDistrictId,
      districtName: parsedDistrictName,
      areaId: parsedAreaId,
      areaName: parsedAreaName,
      areaPincode: parsedAreaPincode,
      displayLabel: parsedDisplayLabel,
      listingLabel: listing,
    );
  }

  static String computeListingLabel({
    String? displayLabel,
    String? areaPincode,
    String? fallbackName,
  }) {
    final dLabel = displayLabel?.trim() ?? '';
    final pCode = areaPincode?.trim() ?? '';
    if (dLabel.isNotEmpty && pCode.isNotEmpty) {
      if (dLabel.endsWith(pCode)) return dLabel;
      return '$dLabel - $pCode';
    } else if (dLabel.isNotEmpty) {
      return dLabel;
    } else if (pCode.isNotEmpty) {
      return pCode;
    } else {
      return fallbackName?.trim() ?? '';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'branch_head_id': id,
    'name': name,
    'branch_head_name': name,
    'username': username,
    'role': role,
    if (roleId != null) 'roleId': roleId,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (districtId != null) 'districtId': districtId,
    if (districtId != null) 'district_id': districtId,
    if (districtName != null) 'districtName': districtName,
    if (districtName != null) 'district_name': districtName,
    if (areaId != null) 'areaId': areaId,
    if (areaId != null) 'area_id': areaId,
    if (areaName != null) 'areaName': areaName,
    if (areaName != null) 'area_name': areaName,
    if (areaPincode != null) 'areaPincode': areaPincode,
    if (areaPincode != null) 'area_pincode': areaPincode,
    if (displayLabel != null) 'displayLabel': displayLabel,
    if (displayLabel != null) 'display_label': displayLabel,
    'listingLabel': listingLabel,
  };
}

/// Paginated result of branch head users from backend listing.
class PaginatedBranchHeads {
  final List<BranchHeadUser> users;
  final int page;
  final int limit;
  final int count;
  final bool hasMore;

  const PaginatedBranchHeads({
    required this.users,
    this.page = 1,
    this.limit = 20,
    this.count = 0,
    this.hasMore = false,
  });

  factory PaginatedBranchHeads.empty() => const PaginatedBranchHeads(
    users: [],
    page: 1,
    limit: 20,
    count: 0,
    hasMore: false,
  );
}

/// Helper determining UI field visibility rules for Coordinator status updates.
class CoordinatorUpdateStatusVisibility {
  final String status;
  final StatusChipModel? selectedChip;

  const CoordinatorUpdateStatusVisibility(this.status, {this.selectedChip});

  /// Schedule (Calendar) is shown when isFollowUp == 1 or isDate == 1 (fallback: not Completed/Cancelled).
  bool get showSchedule =>
      isDateRequiredForStatus(status, chip: selectedChip);

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

  /// Fetches paginated branch head managers from backend GET /api/users/get_branch_heads_for_status_update.
  Future<PaginatedBranchHeads> fetchBranchManagersPaginated({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final baseUri = Uri.parse(ApiConfig.branch_head_listing);
      final queryParams = <String, String>{
        ...baseUri.queryParameters,
        'page': page.toString(),
        'limit': limit.toString(),
      };
      final uri = baseUri.replace(queryParameters: queryParams);

      final response = await client.get(
        uri,
        headers: await tokenStorage.authHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final dynamic rawList = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded['users'] ?? decoded['items'])
            : (decoded is List ? decoded : []);

        final int responsePage = decoded is Map<String, dynamic>
            ? (int.tryParse(decoded['page']?.toString() ?? '') ?? page)
            : page;
        final int responseLimit = decoded is Map<String, dynamic>
            ? (int.tryParse(decoded['limit']?.toString() ?? '') ?? limit)
            : limit;
        final int responseCount = decoded is Map<String, dynamic>
            ? (int.tryParse(decoded['count']?.toString() ?? '') ?? 0)
            : 0;

        if (rawList is List && rawList.isNotEmpty) {
          final users = rawList
              .map((item) => BranchHeadUser.fromJson(item as Map<String, dynamic>))
              .where((u) => u.listingLabel.isNotEmpty || u.name.isNotEmpty)
              .toList();

          final int total = int.tryParse(
            (decoded['total'] ??
                    decoded['totalCount'] ??
                    decoded['total_count'] ??
                    decoded['total_records'])
                ?.toString() ??
                '',
          ) ?? 0;

          final bool hasMore;
          if (total > 0) {
            hasMore = (responsePage * responseLimit) < total;
          } else if (responseCount > responseLimit) {
            // responseCount is greater than page limit, meaning it represents total records
            hasMore = (responsePage * responseLimit) < responseCount;
          } else {
            // When full limit items are returned, there is likely a next page
            hasMore = users.length >= responseLimit;
          }

          return PaginatedBranchHeads(
            users: users,
            page: responsePage,
            limit: responseLimit,
            count: total > 0 ? total : (responseCount > 0 ? responseCount : users.length),
            hasMore: hasMore,
          );
        }
      }
    } catch (_) {}
    return PaginatedBranchHeads.empty();
  }

  /// Fetches branch head managers from backend GET /api/users/get_branch_heads_for_status_update.
  Future<List<BranchHeadUser>> fetchBranchManagers({
    int page = 1,
    int limit = 20,
  }) async {
    final paginated = await fetchBranchManagersPaginated(page: page, limit: limit);
    return paginated.users;
  }

  /// Submits the updated status to the backend POST /api/status endpoint.
  /// Callers must resolve [branchManagerId], [branchManagerName], [districtId],
  /// and [districtName] before calling — use [selectedBranchHead] from the ViewModel.
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
    bool? isFollowUp,
    List<String>? documents,
  }) async {
    final isTest = TokenStorage.isTestEnvironment;

    UserModel? user;
    try {
      user = await UserProfileData.loadUser()
          .timeout(isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 2));
    } catch (_) {}

    final effectiveCreatedBy = (branchManagerId != null && branchManagerId > 0)
        ? branchManagerId
        : (user?.id ?? 0);
    final effectiveCreatedByName = (branchManagerName != null && branchManagerName.isNotEmpty)
        ? branchManagerName
        : ((user?.name != null && user!.name.isNotEmpty)
            ? user.name
            : (user?.username.isNotEmpty == true ? user!.username : 'Coordinator'));
    final effectiveDistrictId = districtId ?? user?.districtId;
    final effectiveDistrictName = districtName ?? user?.districtName;

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
      createdBy: effectiveCreatedBy,
      createdByName: effectiveCreatedByName,
      branchManager: branchManager,
      branchManagerId: effectiveCreatedBy,
      branchManagerName: effectiveCreatedByName,
      districtId: effectiveDistrictId,
      districtName: effectiveDistrictName,
      isFollowUp: resolveIsFollowUpFlag(status, explicitIsFollowUp: isFollowUp),
    );

    final headers = await tokenStorage.authHeaders(includeContentType: true);
    return executeStatusUpdateSubmit(
      client: client,
      headers: headers,
      requestPayload: requestPayload,
      customer: customer,
      status: status,
      effectiveDate: effectiveDate,
      notes: notes,
      documents: documents,
    );
  }
}
