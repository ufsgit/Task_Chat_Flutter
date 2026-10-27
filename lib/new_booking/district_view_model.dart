import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:task_chat/login_page/token_storage.dart';
import '../api/api.dart';
import '../api/authenticated_client.dart';
import 'model/district_model.dart';

/// Default fallback districts for initial display and offline resilience.
const List<DistrictItem> defaultDistricts = [
  DistrictItem(id: 1, name: 'Ernakulam'),
  DistrictItem(id: 2, name: 'Thiruvananthapuram'),
  DistrictItem(id: 3, name: 'Kozhikode'),
  DistrictItem(id: 4, name: 'Thrissur'),
  DistrictItem(id: 5, name: 'Kannur'),
];

/// ViewModel managing state, API fetching, and selection for District dropdown.
class DistrictViewModel extends ChangeNotifier {
  final http.Client _client;
  final bool _isInternalClient;

  bool _isLoading = false;
  String? _errorMessage;
  List<DistrictItem> _districts = defaultDistricts;
  DistrictItem? _selectedDistrict;

  DistrictViewModel({
    http.Client? client,
    DistrictItem? initialDistrict,
    String? initialDistrictName,
  }) : _client = client ?? AuthenticatedClient(),
       _isInternalClient = client == null {
    if (initialDistrict != null) {
      _selectedDistrict = initialDistrict;
    } else if (initialDistrictName != null && initialDistrictName.isNotEmpty) {
      selectDistrictByName(initialDistrictName);
    } else {
      _selectedDistrict = defaultDistricts.first;
    }
  }

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<DistrictItem> get districts => _districts;
  DistrictItem? get selectedDistrict => _selectedDistrict;
  int? get selectedDistrictId => _selectedDistrict?.id;
  String? get selectedDistrictName => _selectedDistrict?.name;

  /// Fetches district listings from ApiConfig.district_listing.
  Future<void> fetchDistricts() async {
    final token = await TokenStorage().getToken();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse(ApiConfig.district_listing);
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
      };

      final response = await _client
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final parsed = DistrictDropdownResponse.fromJson(decoded);
          if (parsed.data.isNotEmpty) {
            _districts = parsed.data;

            // Preserve or re-match current selected district if applicable
            if (_selectedDistrict != null) {
              final match = _districts.where((d) =>
                  d.name.toLowerCase() == _selectedDistrict!.name.toLowerCase() ||
                  d.id == _selectedDistrict!.id).firstOrNull;
              if (match != null) {
                _selectedDistrict = match;
              }
            } else {
              _selectedDistrict = _districts.first;
            }
          }
        } else {
          _errorMessage = 'Invalid response format';
        }
      } else {
        _errorMessage = 'Failed to load districts (${response.statusCode})';
      }
    } catch (e) {
      _errorMessage = 'Network error: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the currently selected district.
  void selectDistrict(DistrictItem? district) {
    if (_selectedDistrict != district) {
      _selectedDistrict = district;
      notifyListeners();
    }
  }

  /// Selects district matching given name (case-insensitive).
  void selectDistrictByName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return;
    }
    final trimmed = name.trim().toLowerCase();
    final match = _districts.where((d) => d.name.toLowerCase() == trimmed).firstOrNull;
    if (match != null) {
      selectDistrict(match);
    } else {
      // If name isn't in current list yet, create a temporary item so it displays
      final temp = DistrictItem(id: 0, name: name.trim());
      selectDistrict(temp);
    }
  }

  /// Selects district by ID.
  void selectDistrictById(int? id) {
    if (id == null) {
      selectDistrict(null);
      return;
    }
    final match = _districts.where((d) => d.id == id).firstOrNull;
    if (match != null) {
      selectDistrict(match);
    }
  }

  /// Clears the district selection.
  void clearSelection() {
    selectDistrict(null);
  }

  @override
  void dispose() {
    if (_isInternalClient) {
      _client.close();
    }
    super.dispose();
  }
}
