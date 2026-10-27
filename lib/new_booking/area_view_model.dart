import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:task_chat/login_page/token_storage.dart';
import '../api/api.dart';
import '../api/authenticated_client.dart';
import 'model/area_model.dart';

/// ViewModel managing state, API fetching, and selection for area dropdowns.
class AreaViewModel extends ChangeNotifier {
  final http.Client _client;
  final bool _isInternalClient;
  Timer? _debounceTimer;

  bool isCoordinator;
  int? districtId;
  bool _isLoading = false;
  String? _errorMessage;
  List<AreaItem> _areas = [];
  AreaItem? _selectedArea;
  String _type;
  String _search;
  int _page;
  int _limit;

  AreaViewModel({
    http.Client? client,
    this.isCoordinator = false,
    this.districtId,
    String defaultType = 'area',
    String defaultSearch = '',
    int defaultPage = 1,
    int defaultLimit = 20,
    AreaItem? initialArea,
  }) : _client = client ?? AuthenticatedClient(),
       _isInternalClient = client == null,
       _type = defaultType,
       _search = defaultSearch,
       _page = defaultPage,
       _limit = defaultLimit,
       _selectedArea = initialArea;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<AreaItem> get areas => _areas;
  AreaItem? get selectedArea => _selectedArea;
  int? get selectedAreaId => _selectedArea?.id;
  String? get selectedAreaName => _selectedArea?.name;
  String get type => _type;
  String get search => _search;
  int get page => _page;
  int get limit => _limit;

  /// Fetches dropdown items from API.
  /// For coordinator, uses ApiConfig.coordinator_area_listing ($baseUrl/api/dropdowns/areas).
  /// For branch manager, uses ApiConfig.area_listing ($baseUrl/api/dropdowns).
  Future<void> fetchAreas({
    bool? isCoordinator,
    int? districtId,
    String? type,
    String? search,
    int? page,
    int? limit,
  }) async {
    final token = await TokenStorage().getToken();
    if (isCoordinator != null) this.isCoordinator = isCoordinator;
    if (districtId != null) this.districtId = districtId;
    final activeType = type ?? _type;
    _type = activeType;
    if (search != null) _search = search;
    if (page != null) _page = page;
    if (limit != null) _limit = limit;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final endpoint = this.isCoordinator
          ? ApiConfig.coordinator_area_listing
          : ApiConfig.area_listing;

      Uri uri = Uri.parse(endpoint);
      final Map<String, String> queryParams = Map<String, String>.from(
        uri.queryParameters,
      );

      if (this.isCoordinator) {
        // Coordinator area endpoint: supports districtId/parentId, page, limit, search
        if (this.districtId != null && this.districtId! > 0) {
          queryParams['districtId'] = this.districtId.toString();
        }
        queryParams['page'] = _page.toString();
        queryParams['limit'] = _limit.toString();
        if (_search.trim().isNotEmpty) {
          queryParams['search'] = _search.trim();
        } else {
          queryParams.remove('search');
        }
      } else {
        // Branch Manager standard area parameters (do NOT touch parentId)
        queryParams['type'] = _type;
        queryParams['page'] = _page.toString();
        queryParams['limit'] = _limit.toString();
        if (_search.trim().isNotEmpty) {
          queryParams['search'] = _search.trim();
        } else {
          queryParams.remove('search');
        }
      }

      uri = uri.replace(queryParameters: queryParams);

      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization': token.startsWith('Bearer ')
              ? token
              : 'Bearer $token',
      };

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final parsed = AreaDropdownResponse.fromJson(decoded);
          _areas = parsed.data;
          if (parsed.type.isNotEmpty) {
            _type = parsed.type;
          }

          if (_selectedArea != null) {
            final matchIndex = _areas.indexWhere(
              (a) => a.id == _selectedArea!.id,
            );
            if (matchIndex != -1) {
              _selectedArea = _areas[matchIndex];
            } else if (this.isCoordinator && _areas.isNotEmpty) {
              _selectedArea = null;
            }
          }
        } else {
          _errorMessage = 'Invalid response format';
        }
      } else {
        _errorMessage = 'Failed to load areas (${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets search query with 300ms debounce and re-fetches from page 1.
  void setSearch(String query) {
    if (_search != query) {
      _search = query;
      _page = 1;
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 300), () {
        fetchAreas(search: query, page: 1);
      });
    }
  }

  /// Sets page number and re-fetches.
  void setPage(int newPage) {
    if (_page != newPage && newPage > 0) {
      _page = newPage;
      fetchAreas(page: newPage);
    }
  }

  /// Sets page limit and re-fetches from page 1.
  void setLimit(int newLimit) {
    if (_limit != newLimit && newLimit > 0) {
      _limit = newLimit;
      _page = 1;
      fetchAreas(limit: newLimit, page: 1);
    }
  }

  /// Sets the currently selected area.
  void selectArea(AreaItem? area) {
    if (_selectedArea != area) {
      _selectedArea = area;
      notifyListeners();
    }
  }

  /// Selects an area by its ID.
  void selectAreaById(int? id) {
    if (id == null) {
      selectArea(null);
      return;
    }
    final match = _areas.where((a) => a.id == id).firstOrNull;
    if (match != null) {
      selectArea(match);
    }
  }

  /// Clears the current area selection.
  void clearSelection() {
    selectArea(null);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (_isInternalClient) {
      _client.close();
    }
    super.dispose();
  }
}
