import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';
import '../core/theme.dart';
import '../login_page/token_storage.dart';
import 'today_model.dart';

/// Centralized in-memory list for Today chat items, populated dynamically from the API.
final List<Map<String, dynamic>> todayChatItems = [];

/// Updates the status and appearance of a chat item by customer title/name.
void updateChatItemStatus({
  required String customerName,
  required String newStatus,
  String? newLocation,
}) {
  final index = todayChatItems.indexWhere(
    (item) =>
        (item['title'] as String?)?.toLowerCase().trim() ==
        customerName.toLowerCase().trim(),
  );

  if (index != -1) {
    final item = todayChatItems[index];
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
}

/// ViewModel managing state, search, filters, and API data fetching for TodayPage.
class TodayViewModel extends ChangeNotifier {
  final http.Client _client;
  final TokenStorage? tokenStorage;

  TodayViewModel({http.Client? client, this.tokenStorage})
      : _client = client ?? http.Client();

  bool _isLoading = false;
  String? _errorMessage;
  List<BookingModel> _bookings = [];
  List<Map<String, dynamic>> _chatItems = [];

  int _selectedFilterIndex = 0; // 0: All, 1: Unread, 2: Pending
  String _selectedStatusFilter = 'All';
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<BookingModel> get bookings => _bookings;
  int get selectedFilterIndex => _selectedFilterIndex;
  String get selectedStatusFilter => _selectedStatusFilter;
  bool get hasActiveFilters => _selectedStatusFilter != 'All';

  List<Map<String, dynamic>> get filteredChatItems {
    final query = _searchQuery.trim().toLowerCase();
    return _chatItems.where((item) {
      final unreadCount = (item['unreadCount'] as int?) ?? 0;
      final title = (item['title'] as String?)?.toLowerCase() ?? '';
      final tagText = (item['tagText'] as String?)?.toLowerCase() ?? '';
      final location = (item['location'] as String?)?.toLowerCase() ?? '';
      final date = (item['date'] as String?)?.toLowerCase() ?? '';
      final isPending = (item['isPending'] as bool?) ?? true;

      if (_selectedFilterIndex == 1 && unreadCount == 0) {
        return false;
      }
      if (_selectedFilterIndex == 2 && !isPending) {
        return false;
      }
      if (_selectedStatusFilter != 'All' &&
          tagText != _selectedStatusFilter.toLowerCase()) {
        return false;
      }
      if (query.isNotEmpty) {
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
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Fetches bookings from the backend API.
  Future<void> fetchBookings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String? token;
    try {
      final isTest = TokenStorage.isTestEnvironment;
      token = await (tokenStorage ?? TokenStorage())
          .getToken()
          .timeout(isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 5));
    } catch (_) {
      // Ignored in test environment if platform channel is absent or times out
    }

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization':
              token.startsWith('Bearer ') ? token : 'Bearer $token',
      };

      var response = await _client
          .get(
            Uri.parse(ApiConfig.bookings),
            headers: headers,
          )
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

          _chatItems = _bookings.map((b) => b.toChatItem()).toList();

          // Sync shared in-memory list for backward compatibility with Coordinator / UpdateStatus
          todayChatItems.clear();
          todayChatItems.addAll(_chatItems);
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
    _chatItems = List<Map<String, dynamic>>.from(todayChatItems);
    notifyListeners();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
