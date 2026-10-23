import 'package:flutter/material.dart';
import '../update_status/coordinators/coordinator_update_status_logic.dart';
import 'coordinator_model.dart';

/// ViewModel managing state, search, and dynamic filtering for the Coordinator screen.
class CoordinatorViewModel extends ChangeNotifier {
  final TextEditingController searchController;
  final bool _internalController;

  int _selectedFilterIndex = 0; // Default to 'All'
  String _selectedStatusFilter = 'All';
  String _selectedManagerFilter = 'All';

  CoordinatorViewModel({
    TextEditingController? searchController,
    int initialFilterIndex = 0,
    String initialStatusFilter = 'All',
    String initialManagerFilter = 'All',
  })  : searchController = searchController ?? TextEditingController(),
        _internalController = searchController == null,
        _selectedFilterIndex = initialFilterIndex,
        _selectedStatusFilter = initialStatusFilter,
        _selectedManagerFilter = initialManagerFilter;

  // Getters
  int get selectedFilterIndex => _selectedFilterIndex;
  List<String> get filters => coordinatorQuickFilters;
  String get selectedStatusFilter => _selectedStatusFilter;
  String get selectedManagerFilter => _selectedManagerFilter;
  List<String> get statusOptions => coordinatorStatusOptions;
  List<String> get branchManagerOptions =>
      ['All', ...availableBranchManagers];

  bool get hasActiveFilters =>
      _selectedStatusFilter != 'All' || _selectedManagerFilter != 'All';

  /// Evaluates and returns the filtered coordinator chat items.
  List<Map<String, dynamic>> get filteredChatItems {
    final query = searchController.text.trim().toLowerCase();
    return coordinatorChatItems.where((item) {
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
    super.dispose();
  }
}
