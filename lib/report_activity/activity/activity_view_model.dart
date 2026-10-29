import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api/api.dart';
import '../../api/authenticated_client.dart';
import '../../login_page/token_storage.dart';
import 'activity_model.dart';

/// ViewModel managing state, API data fetching, searching, and filtering for the Activity section.
class ActivityViewModel extends ChangeNotifier {
  final http.Client _client;
  final bool _isInternalClient;
  final TokenStorage? tokenStorage;
  final Duration debounceDuration;

  ActivityViewModel({
    http.Client? client,
    this.tokenStorage,
    Duration? debounceDuration,
  })  : _client = client ?? AuthenticatedClient(),
        _isInternalClient = client == null,
        debounceDuration = debounceDuration ??
            (TokenStorage.isTestEnvironment
                ? Duration.zero
                : const Duration(milliseconds: 300));

  Timer? _searchDebounceTimer;
  bool _isLoading = false;
  String? _errorMessage;
  List<ActivityModel> _activities = [];

  int _selectedFilterIndex = 0; // 0: 'Today', 1: 'This Week', 2: 'This Month'
  final List<String> _filters = activityTimeFilters;

  String _selectedStatusFilter = 'All';
  final List<String> _statusOptions = const [
    'All',
    'New',
    'Scheduled',
    'Completed',
    'Cancelled',
  ];

  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<ActivityModel> get activities => _activities;
  int get selectedFilterIndex => _selectedFilterIndex;
  List<String> get filters => _filters;
  String get selectedStatusFilter => _selectedStatusFilter;
  List<String> get statusOptions => _statusOptions;
  String get searchQuery => _searchQuery;

  bool get hasActiveFilters => _selectedStatusFilter != 'All';

  List<ActivityModel> get filteredActivities {
    final query = _searchQuery.trim().toLowerCase();
    final selectedTimeFilter = _filters[_selectedFilterIndex];

    return _activities.where((item) {
      // 1. Status Filter from bottom sheet
      if (_selectedStatusFilter != 'All') {
        final status = item.statusTag ?? item.status ?? '';
        if (status.toLowerCase() != _selectedStatusFilter.toLowerCase()) {
          return false;
        }
      }

      // 2. Horizontal Time Filter Chips ('Today', 'This Week', 'This Month')
      if (selectedTimeFilter == 'Today' && item.timeFilter != 'Today') {
        return false;
      } else if (selectedTimeFilter == 'This Week' &&
          item.timeFilter != 'Today' &&
          item.timeFilter != 'This Week') {
        return false;
      } else if (selectedTimeFilter == 'This Month' &&
          item.timeFilter != 'Today' &&
          item.timeFilter != 'This Week' &&
          item.timeFilter != 'This Month') {
        return false;
      }

      // 3. Search query
      if (query.isNotEmpty) {
        final title = item.title.toLowerCase();
        final note = item.noteText?.toLowerCase() ?? '';
        final subtitle = item.subtitleHighlight?.toLowerCase() ?? '';
        final status = item.statusTag?.toLowerCase() ?? '';
        final loc = item.location?.toLowerCase() ?? '';
        return title.contains(query) ||
            note.contains(query) ||
            subtitle.contains(query) ||
            status.contains(query) ||
            loc.contains(query);
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

  void resetFilters() {
    _selectedStatusFilter = 'All';
    _selectedFilterIndex = 0;
    _searchQuery = '';
    notifyListeners();
  }

  void setSearchQuery(String query, {bool immediate = false}) {
    if (immediate || debounceDuration == Duration.zero) {
      _searchDebounceTimer?.cancel();
      if (_searchQuery != query) {
        _searchQuery = query;
        notifyListeners();
      }
      return;
    }

    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(debounceDuration, () {
      if (_searchQuery != query) {
        _searchQuery = query;
        notifyListeners();
      }
    });
  }

  /// Fetches activity history from ApiConfig.history_list endpoint.
  Future<void> fetchHistory({bool force = false}) async {
    if (_isLoading && !force) {
      debugPrint('[ActivityViewModel] Already loading, skipping duplicate call.');
      return;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    debugPrint('>>> [ActivityViewModel] Requesting: ${ApiConfig.history_list}');

    String? token;
    try {
      final isTest = TokenStorage.isTestEnvironment;
      token = await (tokenStorage ?? TokenStorage()).getToken().timeout(
            isTest
                ? const Duration(milliseconds: 50)
                : const Duration(seconds: 2),
            onTimeout: () => null,
          );
    } catch (e) {
      debugPrint('>>> [ActivityViewModel] Token retrieval error/timeout: $e');
    }

    try {
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization':
              token.startsWith('Bearer ') ? token : 'Bearer $token',
      };

      final uri = Uri.parse(ApiConfig.history_list);
      debugPrint('>>> [ActivityViewModel] GET $uri with headers: $headers');

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('<<< [ActivityViewModel] Status: ${response.statusCode}');
      debugPrint('<<< [ActivityViewModel] Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        dynamic rawList;

        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            rawList = data['history'] ??
                data['items'] ??
                data['bookings'] ??
                data['data'];
          } else if (data is List) {
            rawList = data;
          } else {
            rawList = decoded['history'] ??
                decoded['items'] ??
                decoded['bookings'] ??
                decoded['data'];
          }
        } else if (decoded is List) {
          rawList = decoded;
        }

        if (rawList is List) {
          _activities = rawList
              .map(
                  (item) => ActivityModel.fromJson(item as Map<String, dynamic>))
              .toList();
          debugPrint(
              '<<< [ActivityViewModel] Parsed ${_activities.length} activity items');
        } else {
          _activities = [];
        }
        _errorMessage = null;
      } else {
        _errorMessage =
            'Failed to load activity history (${response.statusCode})';
        debugPrint('<<< [ActivityViewModel] Error: $_errorMessage');
      }
    } catch (e, stack) {
      debugPrint('<<< [ActivityViewModel] Network error: $e');
      debugPrint('$stack');
      _errorMessage =
          'Unable to reach server. Please check connection and retry.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    if (_isInternalClient) {
      _client.close();
    }
    super.dispose();
  }
}
