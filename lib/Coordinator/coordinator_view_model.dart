import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';
import '../api/authenticated_client.dart';
import '../login_page/token_storage.dart';
import '../today/today_model.dart';
import '../today/today_view_model.dart';
import '../update_status/coordinators/coordinator_update_status_logic.dart';
import 'coordinator_model.dart';

/// ViewModel managing state, search, API data fetching, and dynamic filtering for Coordinator.
class CoordinatorViewModel extends ChangeNotifier {
  static CoordinatorViewModel? currentSession;

  final http.Client _client;
  final bool _isInternalClient;
  final TokenStorage? tokenStorage;
  final TextEditingController searchController;
  final bool _internalController;
  Timer? _searchDebounceTimer;
  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final String _limit = '15';
  String? _errorMessage;
  List<BookingModel> _bookings = [];
  List<Map<String, dynamic>> _items = [];

  final List<BranchHeadUser> _branchHeadUsers = [];
  final Map<String, int> _managerToDistrictId = {};
  final Map<String, int> _managerToBranchHeadId = {};
  final Set<String> _knownManagers = {};

  static const Map<String, int> defaultDistrictMap = {
    'thiruvananthapuram': 1,
    'kollam': 2,
    'pathanamthitta': 3,
    'alappuzha': 4,
    'kottayam': 5,
    'idukki': 6,
    'ernakulam': 7,
    'thrissur': 8,
    'palakkad': 9,
    'malappuram': 10,
    'kozhikode': 11,
    'wayanad': 12,
    'kannur': 13,
    'kasaragod': 14,
  };

  int _selectedFilterIndex = 0; // Default to 'All'
  String _selectedStatusFilter = 'All';
  String _selectedManagerFilter = 'All';

  final Duration debounceDuration;

  final TodayViewModel? todayViewModel;

  CoordinatorViewModel({
    http.Client? client,
    this.tokenStorage,
    this.todayViewModel,
    TextEditingController? searchController,
    List<Map<String, dynamic>>? initialItems,
    int initialFilterIndex = 0,
    String initialStatusFilter = 'All',
    String initialManagerFilter = 'All',
    Duration? debounceDuration,
  })  : _client = client ?? AuthenticatedClient(),
        _isInternalClient = client == null,
        _items = initialItems != null
            ? List<Map<String, dynamic>>.from(initialItems)
            : (todayViewModel != null && todayViewModel.todayChatItems.isNotEmpty
                ? List<Map<String, dynamic>>.from(todayViewModel.todayChatItems)
                : []),
        debounceDuration = debounceDuration ??
            (TokenStorage.isTestEnvironment
                ? Duration.zero
                : const Duration(milliseconds: 300)),
        searchController = searchController ?? TextEditingController(),
        _internalController = searchController == null,
        _selectedFilterIndex = initialFilterIndex,
        _selectedStatusFilter = initialStatusFilter,
        _selectedManagerFilter =
            initialManagerFilter.toLowerCase().trim() == 'rajesh menon'
                ? 'All'
                : initialManagerFilter {
    currentSession = this;
    for (final it in _items) {
      final m = it['branchManager']?.toString();
      if (m != null && m.trim().isNotEmpty) {
        _knownManagers.add(m.trim());
      }
    }
  }

  // Getters
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  String? get errorMessage => _errorMessage;
  List<BookingModel> get bookings => _bookings;
  int get selectedFilterIndex => _selectedFilterIndex;
  List<String> get filters => coordinatorQuickFilters;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get selectedManagerFilter => _selectedManagerFilter;
  List<String> get statusOptions => coordinatorStatusOptions;

  List<String> get branchManagerOptions {
    final Set<String> names = {};
    if (_branchHeadUsers.isNotEmpty) {
      names.addAll(_branchHeadUsers.map((u) => u.name));
    }
    names.addAll(_knownManagers);
    final dynamicManagers = _items
        .map((e) => e['branchManager']?.toString() ?? '')
        .where((m) =>
            m.trim().isNotEmpty && m.toLowerCase().trim() != 'rajesh menon');
    names.addAll(dynamicManagers);
    names.removeWhere((m) =>
        m.toLowerCase().trim() == 'rajesh menon' || m.trim().isEmpty);

    if (names.isNotEmpty) {
      return ['All', ...names];
    }
    return const ['All'];
  }

  int? _resolveDistrictId(String manager) {
    final trimmed = manager.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'all') return null;

    if (_managerToDistrictId.containsKey(trimmed)) {
      return _managerToDistrictId[trimmed];
    }
    final lower = trimmed.toLowerCase();
    if (_managerToDistrictId.containsKey(lower)) {
      return _managerToDistrictId[lower];
    }

    for (final entry in defaultDistrictMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  int? _resolveBranchHeadId(String manager) {
    final trimmed = manager.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'all') return null;

    if (_managerToBranchHeadId.containsKey(trimmed)) {
      return _managerToBranchHeadId[trimmed];
    }
    final lower = trimmed.toLowerCase();
    if (_managerToBranchHeadId.containsKey(lower)) {
      return _managerToBranchHeadId[lower];
    }

    for (final entry in defaultDistrictMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  void _indexBookingManagers(Iterable<BookingModel> bookings) {
    for (final b in bookings) {
      final bhName = b.branchHeadName?.trim();
      if (bhName != null && bhName.isNotEmpty) {
        _knownManagers.add(bhName);
        if (b.districtId != null && b.districtId! > 0) {
          _managerToDistrictId[bhName] = b.districtId!;
          _managerToDistrictId[bhName.toLowerCase()] = b.districtId!;
        }
        if (b.branchHeadId != null && b.branchHeadId! > 0) {
          _managerToBranchHeadId[bhName] = b.branchHeadId!;
          _managerToBranchHeadId[bhName.toLowerCase()] = b.branchHeadId!;
        }
      }
    }
  }

  /// Fetches the official branch head users from the backend listing.
  Future<void> fetchBranchHeads() async {
    try {
      final headers = await (tokenStorage ?? TokenStorage()).authHeaders();
      final uri = Uri.parse(ApiConfig.branch_head_listing);
      final future = _client.get(uri, headers: headers);
      final response = TokenStorage.isTestEnvironment
          ? await future
          : await future.timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final dynamic rawList = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded['users'] ?? decoded['items'])
            : (decoded is List ? decoded : []);

        if (rawList is List && rawList.isNotEmpty) {
          final heads = rawList
              .map((item) =>
                  BranchHeadUser.fromJson(item as Map<String, dynamic>))
              .where((u) => u.name.isNotEmpty)
              .toList();

          _branchHeadUsers.clear();
          _branchHeadUsers.addAll(heads);

          for (final h in heads) {
            final did = h.districtId ?? h.id;
            _managerToDistrictId[h.name] = did;
            _managerToDistrictId[h.name.toLowerCase().trim()] = did;
            _managerToBranchHeadId[h.name] = h.id;
            _managerToBranchHeadId[h.name.toLowerCase().trim()] = h.id;
          }
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  bool get hasActiveFilters =>
      _selectedStatusFilter != 'All' || _selectedManagerFilter != 'All';

  /// Evaluates and returns the filtered coordinator chat items.
  List<Map<String, dynamic>> get filteredChatItems {
    final sourceList = _items;
    final query = searchController.text.trim().toLowerCase();
    return sourceList.where((item) {
      final unreadCount = (item['unreadCount'] as int?) ?? 0;
      final title = (item['title'] as String?)?.toLowerCase() ?? '';
      final tagText = (item['tagText'] as String?)?.toLowerCase() ?? '';
      final location = (item['location'] as String?)?.toLowerCase() ?? '';
      final date = (item['date'] as String?)?.toLowerCase() ?? '';
      final isPending = (item['isPending'] as bool?) ?? true;
      final branchManager =
          (item['branchManager'] as String?)?.toLowerCase() ?? '';

      // 1. Quick filter tabs: 0 = All, 1 = Unread, 2 = Pending
      if (_selectedFilterIndex == 1 && unreadCount == 0) {
        return false;
      }
      if (_selectedFilterIndex == 2 && !isPending) {
        return false;
      }

      // 2. Status filter from bottom sheet
      if (_selectedStatusFilter != 'All' &&
          tagText != _selectedStatusFilter.toLowerCase()) {
        return false;
      }

      // 3. Branch Manager filter from bottom sheet
      if (_selectedManagerFilter != 'All') {
        final filterDistrictId = _resolveDistrictId(_selectedManagerFilter);
        final itemDistrictId = (item['districtId'] as int?) ??
            (item['booking'] as BookingModel?)?.districtId;
        if (filterDistrictId != null && itemDistrictId != null) {
          if (filterDistrictId != itemDistrictId) return false;
        } else if (branchManager != _selectedManagerFilter.toLowerCase()) {
          return false;
        }
      }

      // 4. Search query
      if (query.isNotEmpty) {
        final searchIndex = item['searchIndex'] as String?;
        if (searchIndex != null && searchIndex.contains(query)) {
          return true;
        }
        return title.contains(query) ||
            tagText.contains(query) ||
            location.contains(query) ||
            date.contains(query) ||
            branchManager.contains(query);
      }
      return true;
    }).toList();
  }

  static const Map<String, int> statusNameToId = {
    'new': 1,
    'scheduled': 2,
    'completed': 3,
    'cancelled': 4,
  };

  /// Builds query parameters for GET /api/bookings based on active filters and page.
  Map<String, String> buildQueryParameters({int page = 1}) {
    final params = <String, String>{
      'page': page.toString(),
      'limit': _limit,
    };

    if (_selectedStatusFilter.isNotEmpty &&
        _selectedStatusFilter.toLowerCase() != 'all') {
      params['status'] = _selectedStatusFilter;
      final statusId = statusNameToId[_selectedStatusFilter.toLowerCase()];
      if (statusId != null) {
        params['statusId'] = statusId.toString();
      }
    }

    final query = searchController.text.trim();
    if (query.isNotEmpty) {
      params['search'] = query;
    }

    if (_selectedManagerFilter.isNotEmpty &&
        _selectedManagerFilter.toLowerCase() != 'all') {
      params['branchManager'] = _selectedManagerFilter;

      final districtId = _resolveDistrictId(_selectedManagerFilter);
      if (districtId != null) {
        params['districtId'] = districtId.toString();
        params['district_id'] = districtId.toString();
      }
      final branchHeadId = _resolveBranchHeadId(_selectedManagerFilter);
      if (branchHeadId != null) {
        params['branchHeadId'] = branchHeadId.toString();
        params['branch_head_id'] = branchHeadId.toString();
      }
    }

    return params;
  }

  /// Fetches bookings from the backend API for Coordinator.
  Future<void> fetchBookings() async {
    if (_isLoading) return;
    _isLoading = true;
    _isLoadingMore = false;
    _currentPage = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final headers = await (tokenStorage ?? TokenStorage()).authHeaders();

      final baseUri = Uri.parse(ApiConfig.bookings);
      final uri =
          baseUri.replace(queryParameters: buildQueryParameters(page: 1));

      final future = _client.get(
        uri,
        headers: headers,
      );
      final response = TokenStorage.isTestEnvironment
          ? await future
          : await future.timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final dynamic rawList = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded['items'] ?? decoded['bookings'])
            : (decoded is List ? decoded : []);

        if (rawList is List) {
          _bookings = rawList
              .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
              .toList();

          _indexBookingManagers(_bookings);

          _items = _bookings.map((booking) {
            final baseChat = booking.toChatItem();
            final assignedManager = (booking.branchHeadName != null &&
                    booking.branchHeadName!.trim().isNotEmpty)
                ? booking.branchHeadName!.trim()
                : ((booking.loginName != null &&
                        booking.loginName!.trim().isNotEmpty)
                    ? booking.loginName!.trim()
                    : 'Unassigned');

            return {
              ...baseChat,
              'role': 'Branch Manager',
              'branchManager': assignedManager,
              'districtId': booking.districtId,
              'branchHeadId': booking.branchHeadId,
            };
          }).toList();

          if (decoded is Map<String, dynamic> &&
              decoded['pagination'] is Map<String, dynamic>) {
            final pagination = decoded['pagination'] as Map<String, dynamic>;
            final totalPages = pagination['totalPages'];
            final total = pagination['total'] ?? pagination['count'];
            final pageVal = pagination['page'] ?? pagination['currentPage'];
            if (pageVal is int) {
              _currentPage = pageVal;
            } else if (pageVal is String) {
              _currentPage = int.tryParse(pageVal) ?? _currentPage;
            }
            if (totalPages is int) {
              _hasMore = _currentPage < totalPages;
            } else if (totalPages is String) {
              final parsed = int.tryParse(totalPages);
              if (parsed != null) _hasMore = _currentPage < parsed;
            } else if (total is int) {
              _hasMore = _bookings.length < total;
            }
          } else {
            final effectiveLimit = int.tryParse(_limit) ?? 15;
            if (_bookings.length < effectiveLimit) {
              _hasMore = false;
            }
          }
        }
      } else {
        _errorMessage = 'Failed to load bookings (${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = 'Connection error';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the next page of bookings for Coordinator and appends them to the list.
  Future<void> loadNextPage() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final queryParams = buildQueryParameters(page: nextPage);

      final headers = await (tokenStorage ?? TokenStorage()).authHeaders();

      final baseUri = Uri.parse(ApiConfig.bookings);
      final uri = baseUri.replace(queryParameters: queryParams);

      final future = _client.get(uri, headers: headers);
      final response = TokenStorage.isTestEnvironment
          ? await future
          : await future.timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final dynamic rawList = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded['items'] ?? decoded['bookings'])
            : (decoded is List ? decoded : []);

        if (rawList is List && rawList.isNotEmpty) {
          final newBookings = rawList
              .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
              .toList();

          _currentPage = nextPage;

          // Deduplicate by ID to prevent duplicate items when appending
          final existingIds = _bookings.map((b) => b.id).toSet();
          final uniqueBookings = newBookings
              .where((b) => !existingIds.contains(b.id))
              .toList();

          if (uniqueBookings.isEmpty) {
            _hasMore = false;
            return;
          }

          _bookings.addAll(uniqueBookings);
          _indexBookingManagers(uniqueBookings);

          final newItems = uniqueBookings.map((booking) {
            final baseChat = booking.toChatItem();
            final assignedManager = (booking.branchHeadName != null &&
                    booking.branchHeadName!.trim().isNotEmpty)
                ? booking.branchHeadName!.trim()
                : ((booking.loginName != null &&
                        booking.loginName!.trim().isNotEmpty)
                    ? booking.loginName!.trim()
                    : 'Unassigned');

            return {
              ...baseChat,
              'role': 'Branch Manager',
              'branchManager': assignedManager,
              'districtId': booking.districtId,
              'branchHeadId': booking.branchHeadId,
            };
          }).toList();

          _items.addAll(newItems);

          if (decoded is Map<String, dynamic> &&
              decoded['pagination'] is Map<String, dynamic>) {
            final pagination = decoded['pagination'] as Map<String, dynamic>;
            final totalPages = pagination['totalPages'];
            final total = pagination['total'] ?? pagination['count'];
            final pageVal = pagination['page'] ?? pagination['currentPage'];
            if (pageVal is int) {
              _currentPage = pageVal;
            } else if (pageVal is String) {
              _currentPage = int.tryParse(pageVal) ?? _currentPage;
            }
            if (totalPages is int) {
              _hasMore = _currentPage < totalPages;
            } else if (totalPages is String) {
              final parsed = int.tryParse(totalPages);
              if (parsed != null) _hasMore = _currentPage < parsed;
            } else if (total is int) {
              _hasMore = _bookings.length < total;
            }
          } else {
            final effectiveLimit = int.tryParse(_limit) ?? 15;
            if (uniqueBookings.length < effectiveLimit) {
              _hasMore = false;
            }
          }
        } else {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
    } catch (_) {
      // Keep state intact
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Updates status in memory and refreshes view immediately.
  void updateStatus(
    String customerName,
    String newStatus, {
    String? newLocation,
    String? newDate,
  }) {
    updateChatItemInList(
      _items,
      customerName: customerName,
      newStatus: newStatus,
      newLocation: newLocation,
      newDate: newDate,
    );
    notifyListeners();
  }

  void setFilterIndex(int index) {
    if (_selectedFilterIndex != index) {
      _selectedFilterIndex = index;
      notifyListeners();
    }
  }

  void setStatusFilter(String status) {
    if (_selectedStatusFilter != status) {
      _selectedStatusFilter = status;
      _currentPage = 1;
      _hasMore = true;
      _items.clear();
      _bookings.clear();
      _isLoading = false;
      notifyListeners();
      unawaited(fetchBookings());
    }
  }

  void setManagerFilter(String manager) {
    final sanitized =
        manager.toLowerCase().trim() == 'rajesh menon' ? 'All' : manager;
    if (_selectedManagerFilter != sanitized) {
      _selectedManagerFilter = sanitized;
      _currentPage = 1;
      _hasMore = true;
      _items.clear();
      _bookings.clear();
      _isLoading = false;
      notifyListeners();
      unawaited(fetchBookings());
    }
  }

  void applyFilters(String status, String manager) {
    final sanitizedManager =
        manager.toLowerCase().trim() == 'rajesh menon' ? 'All' : manager;
    _selectedStatusFilter = status;
    _selectedManagerFilter = sanitizedManager;
    _currentPage = 1;
    _hasMore = true;
    _items.clear();
    _bookings.clear();
    _isLoading = false;
    notifyListeners();
    unawaited(fetchBookings());
  }

  void resetFilters() {
    _selectedStatusFilter = 'All';
    _selectedManagerFilter = 'All';
    _currentPage = 1;
    _hasMore = true;
    _items.clear();
    _bookings.clear();
    _isLoading = false;
    notifyListeners();
    unawaited(fetchBookings());
  }

  void onSearchChanged([String? query, bool immediate = false]) {
    _searchDebounceTimer?.cancel();
    if (immediate || debounceDuration == Duration.zero) {
      _currentPage = 1;
      _hasMore = true;
      unawaited(fetchBookings());
      return;
    }
    _searchDebounceTimer = Timer(debounceDuration, () {
      _currentPage = 1;
      _hasMore = true;
      unawaited(fetchBookings());
    });
  }

  void clearSearch() {
    _searchDebounceTimer?.cancel();
    searchController.clear();
    _currentPage = 1;
    _hasMore = true;
    unawaited(fetchBookings());
  }

  void refresh() {
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (identical(currentSession, this)) {
      currentSession = null;
    }
    _searchDebounceTimer?.cancel();
    if (_internalController) {
      searchController.dispose();
    }
    if (_isInternalClient) {
      _client.close();
    }
    super.dispose();
  }
}
