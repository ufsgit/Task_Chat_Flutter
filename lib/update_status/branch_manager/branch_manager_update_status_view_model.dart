import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';
import '../../customer_details/customer_details_model.dart';
import '../../login_page/token_storage.dart';
import 'branch_manager_update_status_logic.dart';

/// ViewModel managing state, form validation, and submissions for Branch Manager status updates.
class BranchManagerUpdateStatusViewModel extends ChangeNotifier {
  final CustomerDetailsData customer;
  final BranchManagerUpdateStatusLogic _logic;
  final bool _shouldCloseClient;

  late String _selectedStatus;
  late final TextEditingController _notesController;
  late String _scheduleDate;
  late bool _hasBeenScheduled;
  bool _isSaving = false;
  bool _isUploadingDocument = false;
  String? _errorMessage;
  late List<String> _documents;

  BranchManagerUpdateStatusViewModel({
    required this.customer,
    http.Client? client,
    TokenStorage? tokenStorage,
    BranchManagerUpdateStatusLogic? logic,
  })  : _shouldCloseClient = client == null && logic == null,
        _logic = logic ??
            BranchManagerUpdateStatusLogic(
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

    _notesController = TextEditingController(text: customer.notes);
    _scheduleDate =
        (customer.scheduleDate != null && customer.scheduleDate!.isNotEmpty)
            ? customer.scheduleDate!
            : '10/24/2024';
    _documents = List<String>.from(customer.documents);
  }

  // Getters
  String get selectedStatus => _selectedStatus;
  TextEditingController get notesController => _notesController;
  String get scheduleDate => _scheduleDate;
  bool get hasBeenScheduled => _hasBeenScheduled;
  bool get isSaving => _isSaving;
  bool get isUploadingDocument => _isUploadingDocument;
  String? get errorMessage => _errorMessage;
  List<String> get documents => _documents;

  void addDocument(String docUrl) {
    if (!_documents.contains(docUrl)) {
      _documents.add(docUrl);
      notifyListeners();
    }
  }

  void removeDocument(String docUrl) {
    if (_documents.remove(docUrl)) {
      notifyListeners();
    }
  }

  void setUploadingDocument(bool uploading) {
    _isUploadingDocument = uploading;
    notifyListeners();
  }

  List<String> get availableOptions =>
      getAvailableStatusOptions(hasBeenScheduled: _hasBeenScheduled);

  UpdateStatusVisibility get visibility =>
      UpdateStatusVisibility(_selectedStatus);

  bool get showSchedule => visibility.showSchedule;

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
        documents: _documents,
      );

      if (success) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated to $_selectedStatus for ${customer.name}'),
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
      _errorMessage = 'Connection error';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection error'),
            backgroundColor: Color(0xFFEF4444),
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

/// Backward compatibility alias
typedef UpdateStatusViewModel = BranchManagerUpdateStatusViewModel;
