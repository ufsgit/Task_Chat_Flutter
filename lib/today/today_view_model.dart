import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';
import '../api/authenticated_client.dart';
import '../core/theme.dart';
import '../login_page/token_storage.dart';
import 'today_model.dart';

/// Fallback list for legacy / unauthenticated usage when no TodayViewModel session is active.
final List<Map<String, dynamic>> _legacyTodayChatItems = [];

/// Centralized in-memory list for Today chat items, scoped to the current authenticated session.
/// Scoped [TodayViewModel.todayChatItems] should be preferred.
List<Map<String, dynamic>> get todayChatItems =>
    TodayViewModel.currentSession?.todayChatItems ?? _legacyTodayChatItems;

/// Updates the status and appearance of a chat item in a given list of chat items by customer title/name.
bool updateChatItemInList(
  List<Map<String, dynamic>> items, {
  required String customerName,
  required String newStatus,
  String? newLocation,
  String? newDate,
}) {
  final index = items.indexWhere(
    (item) =>
        (item['title'] as String?)?.toLowerCase().trim() ==
        customerName.toLowerCase().trim(),
  );

  if (index != -1) {
    final item = items[index];
    item['tagText'] = newStatus;

    if (newLocation != null && newLocation.isNotEmpty) {
      item['location'] = newLocation;
    }

    if (newDate != null && newDate.isNotEmpty) {
      item['date'] = newDate;
      item['scheduleDate'] = newDate;
    }

    switch (newStatus.toLowerCase()) {
      case 'completed':
        item['tagBgColor'] = AppColors.completedBg;
        item['tagTextColor'] = AppColors.completedText;
        item['isPending'] = false;
        break;
      case 'new':
        item['tagBgColor'] = AppColors.newBg;
        item['tagTextColor'] = AppColors.newText;
        item['isPending'] = true;
        break;
      case 'scheduled':
        item['tagBgColor'] = const Color(0xFFFEF3C7);
        item['tagTextColor'] = const Color(0xFFD97706);
        item['isPending'] = true;
        break;
      case 'cancelled':
        item['tagBgColor'] = AppColors.cancelledBg;
        item['tagTextColor'] = AppColors.cancelledText;
        item['isPending'] = false;
        break;
    }
    return true;
  }
  return false;
}

/// Updates the status and appearance of a chat item by customer title/name in the active session.
void updateChatItemStatus({
  required String customerName,
  required String newStatus,
  String? newLocation,
  String? newDate,
}) {
  final targetList =
      TodayViewModel.currentSession?.todayChatItems ?? _legacyTodayChatItems;
  final updated = updateChatItemInList(
    targetList,
    customerName: customerName,
    newStatus: newStatus,
    newLocation: newLocation,
    newDate: newDate,
  );
  if (targetList != _legacyTodayChatItems) {
    updateChatItemInList(
      _legacyTodayChatItems,
      customerName: customerName,
      newStatus: newStatus,
      newLocation: newLocation,
      newDate: newDate,
    );
  }
  if (updated) {
    _todayVersion++;
  }
}

int _todayVersion = 0;
int get todayChatItemsVersion => _todayVersion;
void incrementTodayChatItemsVersion() => _todayVersion++;

/// ViewModel managing state, search, filters, and API data fetching for TodayPage.
class TodayViewModel extends ChangeNotifier {
  static TodayViewModel? currentSession;

  bool _isDisposed = false;
  bool get isDisposed => _isDisposed;

  static final List<VoidCallback> _onResetCallbacks = [];
  static void registerOnReset(VoidCallback callback) => _onResetCallbacks.add(callback);
  static void unregisterOnReset(VoidCallback callback) => _onResetCallbacks.remove(callback);

  /// Resets the current session, clearing all in-memory chat items and unauthenticated state.
  static void resetSession() {
    final session = currentSession;
    currentSession = null;
    _legacyTodayChatItems.clear();
    if (session != null && !session._isDisposed) {
      session.clear();
    }
    for (final cb in List.of(_onResetCallbacks)) {
      try {
        cb();
      } catch (_) {}
    }
  }

  final http.Client _client;
  final bool _isInternalClient;
  final TokenStorage? tokenStorage;
  final Duration debounceDuration;

  TodayViewModel({
    http.Client? client,
    this.tokenStorage,
    Duration? debounceDuration,
    List<Map<String, dynamic>>? initialChatItems,
  }) : _client = client ?? AuthenticatedClient(),
       _isInternalClient = client == null,
       debounceDuration =
           debounceDuration ??
           (TokenStorage.isTestEnvironment
               ? Duration.zero
               : const Duration(milliseconds: 300)) {
    if (initialChatItems != null) {
      _chatItems.addAll(initialChatItems);
    } else if (currentSession != null &&
        currentSession!.todayChatItems.isNotEmpty &&
        !identical(currentSession, this)) {
      _chatItems.addAll(currentSession!.todayChatItems);
    } else if (_legacyTodayChatItems.isNotEmpty) {
      _chatItems.addAll(_legacyTodayChatItems);
    }
    currentSession = this;
  }

  Timer? _searchDebounceTimer;
  bool _isLoading = false;
  String? _errorMessage;
  List<BookingModel> _bookings = [];
  final List<Map<String, dynamic>> _chatItems = [];

  List<Map<String, dynamic>> get chatItems => _chatItems;
  List<Map<String, dynamic>> get todayChatItems => _chatItems;

  /// Clears stored chat items and bookings for this scoped ViewModel session.
  void clear() {
    _bookings.clear();
    _chatItems.clear();
    _errorMessage = null;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  int _selectedFilterIndex = 0; // 0: All, 1: Unread, 2: Pending
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';
  String? _districtId;
  String? _dateFrom;
  String? _dateTo;
  String? _filterRole;
  String? _page;
  String? _limit;

  static const Map<String, String> roleNames = {
    '1': 'Company',
    '2': 'Coordinator',
    '3': 'Branch Head',
    '4': 'Dealer',
    '5': 'Customer',
  };

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<BookingModel> get bookings => _bookings;
  int get selectedFilterIndex => _selectedFilterIndex;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get searchQuery => _searchQuery;
  String? get districtId => _districtId;
  String? get dateFrom => _dateFrom;
  String? get dateTo => _dateTo;
  String? get filterRole => _filterRole;
  String? get filterRoleName =>
      _filterRole != null ? roleNames[_filterRole] ?? _filterRole : null;
  String? get page => _page;
  String? get limit => _limit;

  bool get hasActiveFilters =>
      _selectedStatusFilter != 'All' ||
      (_districtId != null && _districtId!.trim().isNotEmpty) ||
      (_dateFrom != null && _dateFrom!.trim().isNotEmpty) ||
      (_dateTo != null && _dateTo!.trim().isNotEmpty) ||
      (_filterRole != null && _filterRole!.trim().isNotEmpty);

  List<Map<String, dynamic>> get filteredChatItems {
    final query = _searchQuery.trim().toLowerCase();
    return _chatItems.where((item) {
      final tagText = (item['tagText'] as String?)?.toLowerCase() ?? '';

      if (_selectedStatusFilter != 'All' &&
          tagText != _selectedStatusFilter.toLowerCase()) {
        return false;
      }
      if (query.isNotEmpty) {
        final searchIndex = item['searchIndex'] as String?;
        if (searchIndex != null) {
          return searchIndex.contains(query);
        }
        final title = (item['title'] as String?)?.toLowerCase() ?? '';
        final location = (item['location'] as String?)?.toLowerCase() ?? '';
        final date = (item['date'] as String?)?.toLowerCase() ?? '';
        return title.contains(query) ||
            tagText.contains(query) ||
            location.contains(query) ||
            date.contains(query);
      }
      return true;
    }).toList();
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
      notifyListeners();
      fetchBookings();
    }
  }

  void setDistrictId(String? districtId) {
    if (_districtId != districtId) {
      _districtId = districtId;
      notifyListeners();
      fetchBookings();
    }
  }

  void setDateRange({String? from, String? to}) {
    if (_dateFrom != from || _dateTo != to) {
      _dateFrom = from;
      _dateTo = to;
      notifyListeners();
      fetchBookings();
    }
  }

  void setFilterRole(String? role) {
    if (_filterRole != role) {
      _filterRole = role;
      notifyListeners();
      fetchBookings();
    }
  }

  void setPagination({String? page, String? limit}) {
    if (_page != page || _limit != limit) {
      _page = page;
      _limit = limit;
      notifyListeners();
      fetchBookings();
    }
  }

  void applyFilters({
    String? status,
    String? districtId,
    String? dateFrom,
    String? dateTo,
    String? filterRole,
    String? page,
    String? limit,
  }) {
    if (status != null) _selectedStatusFilter = status;
    _districtId = districtId;
    _dateFrom = dateFrom;
    _dateTo = dateTo;
    _filterRole = filterRole;
    if (page != null) _page = page;
    if (limit != null) _limit = limit;
    notifyListeners();
    fetchBookings();
  }

  void resetFilters() {
    _selectedStatusFilter = 'All';
    _districtId = null;
    _dateFrom = null;
    _dateTo = null;
    _filterRole = null;
    _page = null;
    _limit = null;
    _searchQuery = '';
    notifyListeners();
    fetchBookings();
  }

  void setSearchQuery(String query, {bool immediate = false}) {
    if (immediate || debounceDuration == Duration.zero) {
      _searchDebounceTimer?.cancel();
      if (_searchQuery != query) {
        _searchQuery = query;
        notifyListeners();
        fetchBookings();
      }
      return;
    }
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(debounceDuration, () {
      if (_searchQuery != query) {
        _searchQuery = query;
        notifyListeners();
        fetchBookings();
      }
    });
  }

  /// Builds query parameters for GET /api/bookings.
  /// Omits any parameters that are null, empty, or 'all'.
  Map<String, String> buildQueryParameters({
    String? search,
    String? districtId,
    String? dateFrom,
    String? dateTo,
    String? filterRole,
    String? status,
    String? page,
    String? limit,
  }) {
    final queryParameters = <String, String>{};

    final s = (search ?? _searchQuery).trim();
    if (s.isNotEmpty) {
      queryParameters['search'] = s;
    }

    final dId = (districtId ?? _districtId)?.trim();
    if (dId != null && dId.isNotEmpty && dId.toLowerCase() != 'null') {
      queryParameters['districtId'] = dId;
    }

    final dFrom = (dateFrom ?? _dateFrom)?.trim();
    if (dFrom != null && dFrom.isNotEmpty && dFrom.toLowerCase() != 'null') {
      queryParameters['dateFrom'] = dFrom;
    }

    final dTo = (dateTo ?? _dateTo)?.trim();
    if (dTo != null && dTo.isNotEmpty && dTo.toLowerCase() != 'null') {
      queryParameters['dateTo'] = dTo;
    }

    final role = (filterRole ?? _filterRole)?.trim();
    if (role != null && role.isNotEmpty && role.toLowerCase() != 'null') {
      queryParameters['filterRole'] = role;
    }

    final st = (status ?? _selectedStatusFilter).trim();
    if (st.isNotEmpty &&
        st.toLowerCase() != 'all' &&
        st.toLowerCase() != 'null') {
      queryParameters['status'] = st;
    }

    final p = (page ?? _page)?.trim();
    if (p != null && p.isNotEmpty && p.toLowerCase() != 'null') {
      queryParameters['page'] = p;
    }

    final l = (limit ?? _limit)?.trim();
    if (l != null && l.isNotEmpty && l.toLowerCase() != 'null') {
      queryParameters['limit'] = l;
    }

    return queryParameters;
  }

  /// Fetches bookings from the backend API using query parameters.
  Future<void> fetchBookings({
    Map<String, String>? queryParams,
    bool force = false,
  }) async {
    if (_isLoading && !force) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String? token;
    try {
      final isTest = TokenStorage.isTestEnvironment;
      token = await (tokenStorage ?? TokenStorage()).getToken().timeout(
        isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 5),
      );
    } catch (_) {
      // Ignored in test environment if platform channel is absent or times out
    }

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization': token.startsWith('Bearer ')
              ? token
              : 'Bearer $token',
      };

      final params = queryParams ?? buildQueryParameters();
      final baseUri = Uri.parse(ApiConfig.bookings);
      final uri = params.isNotEmpty
          ? baseUri.replace(queryParameters: params)
          : baseUri;

      var response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final dynamic rawList = decoded is Map<String, dynamic>
            ? (decoded['data'] ?? decoded['items'] ?? decoded['bookings'])
            : (decoded is List ? decoded : []);

        if (rawList is List) {
          _bookings = rawList
              .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
              .toList();

          _chatItems.clear();
          _chatItems.addAll(_bookings.map((b) => b.toChatItem()));
          incrementTodayChatItemsVersion();
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

  /// Updates status in memory and refreshes view immediately.
  void updateStatus(
    String customerName,
    String newStatus, {
    String? newLocation,
    String? newDate,
  }) {
    updateChatItemInList(
      _chatItems,
      customerName: customerName,
      newStatus: newStatus,
      newLocation: newLocation,
      newDate: newDate,
    );
    if (_legacyTodayChatItems.isNotEmpty) {
      updateChatItemInList(
        _legacyTodayChatItems,
        customerName: customerName,
        newStatus: newStatus,
        newLocation: newLocation,
        newDate: newDate,
      );
    }
    incrementTodayChatItemsVersion();
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (identical(currentSession, this)) {
      currentSession = null;
    }
    _searchDebounceTimer?.cancel();
    if (_isInternalClient) {
      _client.close();
    }
    super.dispose();
  }
}
