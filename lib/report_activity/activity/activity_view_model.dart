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
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _limit = 20;
  int _totalCount = 0;
  String? _errorMessage;
  List<ActivityModel> _activities = [];

  int _selectedFilterIndex = 0; // 0: 'All', 1: 'Today', 2: 'This Week', 3: 'This Month'
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
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  int get limit => _limit;
  int get totalCount => _totalCount;
  String? get errorMessage => _errorMessage;
  List<ActivityModel> get activities => _activities;
  int get selectedFilterIndex => _selectedFilterIndex;
  List<String> get filters => _filters;
  String get selectedStatusFilter => _selectedStatusFilter;
  List<String> get statusOptions => _statusOptions;
  String get searchQuery => _searchQuery;
  http.Client get client => _client;

  void setLimit(int limit) {
    _limit = limit;
  }

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

      // 2. Horizontal Time Filter Chips ('All', 'Today', 'This Week', 'This Month')
      if (selectedTimeFilter == 'All') {
        // Show all activities regardless of date
      } else if (selectedTimeFilter == 'Today' && item.timeFilter != 'Today') {
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
    _isLoadingMore = false;
    _hasMore = true;
    _currentPage = 1;
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
        int? responsePage;
        int? responseLimit;
        int? responseCount;

        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            rawList = data['history'] ??
                data['items'] ??
                data['bookings'] ??
                data['data'];
            responsePage = int.tryParse(data['page']?.toString() ?? '');
            responseLimit = int.tryParse(data['limit']?.toString() ?? '');
            responseCount = int.tryParse(data['count']?.toString() ?? '');
          } else if (data is List) {
            rawList = data;
          } else {
            rawList = decoded['history'] ??
                decoded['items'] ??
                decoded['bookings'] ??
                decoded['data'];
          }
          responsePage ??= int.tryParse(decoded['page']?.toString() ?? '');
          responseLimit ??= int.tryParse(decoded['limit']?.toString() ?? '');
          responseCount ??= int.tryParse(decoded['count']?.toString() ?? '');
        } else if (decoded is List) {
          rawList = decoded;
        }

        if (responseLimit != null && responseLimit > 0) {
          _limit = responseLimit;
        }
        if (responseCount != null) {
          _totalCount = responseCount;
        }
        if (responsePage != null && responsePage > 0) {
          _currentPage = responsePage;
        } else {
          _currentPage = 1;
        }

        if (rawList is List) {
          _activities = rawList
              .map(
                  (item) => ActivityModel.fromJson(item as Map<String, dynamic>))
              .toList();
          debugPrint(
              '<<< [ActivityViewModel] Parsed ${_activities.length} activity items');

          if (_activities.isEmpty) {
            _hasMore = false;
          } else if (_activities.length < _limit) {
            _hasMore = false;
          } else if (_totalCount > 0 && _activities.length >= _totalCount) {
            _hasMore = false;
          } else {
            _hasMore = true;
          }
        } else {
          _activities = [];
          _hasMore = false;
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

  /// Fetches the next page of activity history and appends to the current list.
  Future<void> loadNextPage() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    final nextPage = _currentPage + 1;
    final queryParams = <String, String>{
      'page': nextPage.toString(),
      'limit': _limit.toString(),
    };

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

      final baseUri = Uri.parse(ApiConfig.history_list);
      final uri = baseUri.replace(queryParameters: queryParams);
      debugPrint('>>> [ActivityViewModel] GET $uri with headers: $headers');

      final future = _client.get(uri, headers: headers);
      final response = TokenStorage.isTestEnvironment
          ? await future
          : await future.timeout(const Duration(seconds: 10));

      debugPrint('<<< [ActivityViewModel] Status: ${response.statusCode}');
      debugPrint('<<< [ActivityViewModel] Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        dynamic rawList;
        int? responsePage;
        int? responseLimit;
        int? responseCount;

        if (decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          if (data is Map<String, dynamic>) {
            rawList = data['history'] ??
                data['items'] ??
                data['bookings'] ??
                data['data'];
            responsePage = int.tryParse(data['page']?.toString() ?? '');
            responseLimit = int.tryParse(data['limit']?.toString() ?? '');
            responseCount = int.tryParse(data['count']?.toString() ?? '');
          } else if (data is List) {
            rawList = data;
          } else {
            rawList = decoded['history'] ??
                decoded['items'] ??
                decoded['bookings'] ??
                decoded['data'];
          }
          responsePage ??= int.tryParse(decoded['page']?.toString() ?? '');
          responseLimit ??= int.tryParse(decoded['limit']?.toString() ?? '');
          responseCount ??= int.tryParse(decoded['count']?.toString() ?? '');
        } else if (decoded is List) {
          rawList = decoded;
        }

        if (responseLimit != null && responseLimit > 0) {
          _limit = responseLimit;
        }
        if (responseCount != null) {
          _totalCount = responseCount;
        }

        if (rawList is List && rawList.isNotEmpty) {
          final newItems = rawList
              .map(
                  (item) => ActivityModel.fromJson(item as Map<String, dynamic>))
              .toList();

          _currentPage = responsePage ?? nextPage;
          _activities.addAll(newItems);
          debugPrint(
              '<<< [ActivityViewModel] Added ${newItems.length} items (total: ${_activities.length})');

          if (newItems.length < _limit) {
            _hasMore = false;
          } else if (_totalCount > 0 && _activities.length >= _totalCount) {
            _hasMore = false;
          } else {
            _hasMore = true;
          }
        } else {
          _hasMore = false;
        }
      } else {
        debugPrint(
            '<<< [ActivityViewModel] loadNextPage failed (${response.statusCode})');
      }
    } catch (e, stack) {
      debugPrint('<<< [ActivityViewModel] loadNextPage error: $e');
      debugPrint('$stack');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Fetches detailed timeline history for a specific booking from ApiConfig.report_graph_bybookingid.
  Future<List<Map<String, dynamic>>?> fetchHistoryByBookingId(dynamic bookingId) async {
    if (bookingId == null) return null;
    final bId = bookingId.toString().trim();
    if (bId.isEmpty) return null;

    final url = ApiConfig.reportGraphByBookingId(bId);
    debugPrint('>>> [ActivityViewModel] Requesting history by booking id: $url');

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

      final uri = Uri.parse(url);
      final future = _client.get(uri, headers: headers);
      final response = TokenStorage.isTestEnvironment
          ? await future
          : await future.timeout(const Duration(seconds: 10));

      debugPrint(
          '<<< [ActivityViewModel] fetchHistoryByBookingId Status: ${response.statusCode}');
      debugPrint(
          '<<< [ActivityViewModel] fetchHistoryByBookingId Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = json.decode(response.body);
        final list = extractHistoryList(decoded);
        if (list != null && decoded is Map<String, dynamic>) {
          final data = decoded['data'];
          final totalCount = int.tryParse(
              (data is Map ? data['count'] ?? data['total'] : decoded['count'] ?? decoded['total'])
                      ?.toString() ??
                  '');
          final limit = int.tryParse(
              (data is Map ? data['limit'] : decoded['limit'])?.toString() ?? '');
          int page = 1;
          while (totalCount != null &&
              list.length < totalCount &&
              !TokenStorage.isTestEnvironment) {
            page++;
            final nextUri = uri.replace(queryParameters: {
              'page': page.toString(),
              'limit': (limit ?? 20).toString(),
            });
            final nextResp = await _client
                .get(nextUri, headers: headers)
                .timeout(const Duration(seconds: 10));
            if (nextResp.statusCode >= 200 && nextResp.statusCode < 300) {
              final nextDecoded = json.decode(nextResp.body);
              final nextItems = extractHistoryList(nextDecoded);
              if (nextItems != null && nextItems.isNotEmpty) {
                list.addAll(nextItems);
              } else {
                break;
              }
            } else {
              break;
            }
          }
        }
        return list;
      }
    } catch (e, stack) {
      debugPrint('<<< [ActivityViewModel] fetchHistoryByBookingId error: $e');
      debugPrint('$stack');
    }
    return null;
  }

  /// Robust extractor for history lists across diverse backend response structures.
  static List<Map<String, dynamic>>? extractHistoryList(dynamic decoded) {
    if (decoded == null) return null;
    dynamic rawList;
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        rawList = data['history'] ??
            data['items'] ??
            data['timeline'] ??
            data['activity'] ??
            data['logs'] ??
            data['rows'] ??
            data['bookings'] ??
            data['data'];
      } else if (data is List) {
        rawList = data;
      } else {
        rawList = decoded['history'] ??
            decoded['items'] ??
            decoded['timeline'] ??
            decoded['activity'] ??
            decoded['logs'] ??
            decoded['rows'] ??
            decoded['bookings'] ??
            decoded['data'];
      }
    } else if (decoded is List) {
      rawList = decoded;
    }

    if (rawList is List) {
      return rawList
          .whereType<Map<String, dynamic>>()
          .toList();
    }
    return null;
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
