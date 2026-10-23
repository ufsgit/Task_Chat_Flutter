import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';
import '../core/theme.dart';
import '../login_page/token_storage.dart';
import '../today/today_model.dart';
import '../today/today_view_model.dart';
import '../update_status/coordinators/coordinator_update_status_logic.dart';
import 'coordinator_model.dart';

/// ViewModel managing state, search, API data fetching, and dynamic filtering for Coordinator.
class CoordinatorViewModel extends ChangeNotifier {
  final http.Client _client;
  final TokenStorage? tokenStorage;
  final TextEditingController searchController;
  final bool _internalController;

  bool _isLoading = false;
  String? _errorMessage;
  List<BookingModel> _bookings = [];
  List<Map<String, dynamic>> _items = [];

  int _selectedFilterIndex = 0; // Default to 'All'
  String _selectedStatusFilter = 'All';
  String _selectedManagerFilter = 'All';

  CoordinatorViewModel({
    http.Client? client,
    this.tokenStorage,
    TextEditingController? searchController,
    int initialFilterIndex = 0,
    String initialStatusFilter = 'All',
    String initialManagerFilter = 'All',
  })  : _client = client ?? http.Client(),
        searchController = searchController ?? TextEditingController(),
        _internalController = searchController == null,
        _selectedFilterIndex = initialFilterIndex,
        _selectedStatusFilter = initialStatusFilter,
        _selectedManagerFilter = initialManagerFilter;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<BookingModel> get bookings => _bookings;
  int get selectedFilterIndex => _selectedFilterIndex;
  List<String> get filters => coordinatorQuickFilters;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get selectedManagerFilter => _selectedManagerFilter;
  List<String> get statusOptions => coordinatorStatusOptions;

  List<String> get branchManagerOptions {
    final dynamicManagers = _items
        .map((e) => e['branchManager']?.toString() ?? '')
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();
    if (dynamicManagers.isNotEmpty) {
      return ['All', ...dynamicManagers];
    }
    return ['All', ...availableBranchManagers];
  }

  bool get hasActiveFilters =>
      _selectedStatusFilter != 'All' || _selectedManagerFilter != 'All';

  /// Evaluates and returns the filtered coordinator chat items.
  List<Map<String, dynamic>> get filteredChatItems {
    final sourceList = _items.isNotEmpty ? _items : coordinatorChatItems;
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
      if (_selectedManagerFilter != 'All' &&
          branchManager != _selectedManagerFilter.toLowerCase()) {
        return false;
      }

      // 4. Search query
      if (query.isNotEmpty) {
        return title.contains(query) ||
            tagText.contains(query) ||
            location.contains(query) ||
            date.contains(query) ||
            branchManager.contains(query);
      }
      return true;
    }).toList();
  }

  /// Fetches bookings from the backend API for Coordinator.
  Future<void> fetchBookings() async {
    if (_isLoading) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String? token;
    try {
      if (TokenStorage.isTestEnvironment) {
        token = await (tokenStorage ?? TokenStorage()).getToken();
      } else {
        token = await (tokenStorage ?? TokenStorage())
            .getToken()
            .timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Ignored in test environment
    }

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
      };

      final future = _client.get(
        Uri.parse(ApiConfig.bookings),
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

          final managers = availableBranchManagers;
          _items = _bookings.asMap().entries.map((entry) {
            final index = entry.key;
            final booking = entry.value;
            final baseChat = booking.toChatItem();
            final assignedManager = (booking.branchHeadName != null &&
                    booking.branchHeadName!.trim().isNotEmpty)
                ? booking.branchHeadName!.trim()
                : ((booking.loginName != null &&
                        booking.loginName!.trim().isNotEmpty)
                    ? booking.loginName!.trim()
                    : managers[index % managers.length]);

            return {
              ...baseChat,
              'role': 'Branch Manager',
              'branchManager': assignedManager,
            };
          }).toList();

          // Sync shared in-memory list for backward compatibility
          todayChatItems.clear();
          todayChatItems.addAll(_items);
        }
      } else {
        _errorMessage = 'Failed to load bookings (${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
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
  }) {
    updateChatItemStatus(
      customerName: customerName,
      newStatus: newStatus,
      newLocation: newLocation,
    );

    final index = _items.indexWhere(
      (item) =>
          (item['title'] as String?)?.toLowerCase().trim() ==
          customerName.toLowerCase().trim(),
    );

    if (index != -1) {
      final item = _items[index];
      item['tagText'] = newStatus;
      if (newLocation != null && newLocation.isNotEmpty) {
        item['location'] = newLocation;
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
    }

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
      notifyListeners();
    }
  }

  void setManagerFilter(String manager) {
    if (_selectedManagerFilter != manager) {
      _selectedManagerFilter = manager;
      notifyListeners();
    }
  }

  void applyFilters(String status, String manager) {
    _selectedStatusFilter = status;
    _selectedManagerFilter = manager;
    notifyListeners();
  }

  void resetFilters() {
    _selectedStatusFilter = 'All';
    _selectedManagerFilter = 'All';
    notifyListeners();
  }

  void clearSearch() {
    searchController.clear();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  @override
  void dispose() {
    if (_internalController) {
      searchController.dispose();
    }
    _client.close();
    super.dispose();
  }
}
