import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';
import '../../customer_details/customer_details_model.dart';
import '../../login_page/token_storage.dart';
import '../branch_manager/branch_manager_update_status_logic.dart';
import 'coordinator_update_status_logic.dart';

/// ViewModel managing state, form validation, and submissions for Coordinator status updates.
class CoordinatorUpdateStatusViewModel extends ChangeNotifier {
  final CustomerDetailsData customer;
  final CoordinatorUpdateStatusLogic _logic;
  final bool _shouldCloseClient;

  late String _selectedStatus;
  late final TextEditingController _notesController;
  late String _scheduleDate;
  late String _selectedBranchManager;
  late bool _hasBeenScheduled;
  bool _isSaving = false;
  String? _errorMessage;

  CoordinatorUpdateStatusViewModel({
    required this.customer,
    http.Client? client,
    TokenStorage? tokenStorage,
    CoordinatorUpdateStatusLogic? logic,
  })  : _shouldCloseClient = client == null && logic == null,
        _logic = logic ??
            CoordinatorUpdateStatusLogic(
              client: client,
              tokenStorage: tokenStorage,
            ) {
    _hasBeenScheduled = customer.hasBeenScheduled ||
        customer.status.toLowerCase() == 'scheduled' ||
        customer.status.toLowerCase() == 'completed';

    _selectedStatus = customer.status.toLowerCase() == 'new'
        ? 'Scheduled'
        : customer.status;

    if (!_hasBeenScheduled && _selectedStatus.toLowerCase() == 'completed') {
      _selectedStatus = 'Scheduled';
    }

    _notesController = TextEditingController(text: '');
    _scheduleDate = '10/24/2024';
    _selectedBranchManager = availableBranchManagers.first;
  }

  // Getters
  String get selectedStatus => _selectedStatus;
  TextEditingController get notesController => _notesController;
  String get scheduleDate => _scheduleDate;
  String get selectedBranchManager => _selectedBranchManager;
  bool get hasBeenScheduled => _hasBeenScheduled;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  List<String> get availableOptions =>
      getAvailableStatusOptions(hasBeenScheduled: _hasBeenScheduled);

  CoordinatorUpdateStatusVisibility get visibility =>
      CoordinatorUpdateStatusVisibility(_selectedStatus);

  bool get showSchedule => visibility.showSchedule;
  bool get showBranchManager => visibility.showBranchManager;

  void setStatus(String status) {
    if (_selectedStatus != status) {
      _selectedStatus = status;
      notifyListeners();
    }
  }

  void setScheduleDate(String date) {
    if (_scheduleDate != date) {
      _scheduleDate = date;
      notifyListeners();
    }
  }

  void setBranchManager(String manager) {
    if (_selectedBranchManager != manager) {
      _selectedBranchManager = manager;
      notifyListeners();
    }
  }

  /// Saves the status update to the backend API and shows user feedback.
  Future<bool> saveStatus(BuildContext context) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _logic.submitStatusUpdate(
        customer: customer,
        status: _selectedStatus,
        scheduleDate: _scheduleDate,
        notes: _notesController.text,
        branchManager: _selectedBranchManager,
      );

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Status updated to $_selectedStatus for ${customer.name} (Assigned: $_selectedBranchManager)',
              ),
              backgroundColor: AppColors.primaryGreen,
              duration: const Duration(seconds: 1),
            ),
          );
        }
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update status on server';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update status on server'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
        _isSaving = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error: $e';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    if (_shouldCloseClient) {
      _logic.client.close();
    }
    super.dispose();
  }
}
