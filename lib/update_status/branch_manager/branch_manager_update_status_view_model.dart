import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/widgets/app_pill_notification.dart';
import '../../customer_details/customer_details_model.dart';
import '../../login_page/token_storage.dart';
import '../models/status_chip_model.dart';
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
  bool _isLoadingChips = false;
  bool _isUploadingDocument = false;
  String? _errorMessage;
  late List<String> _documents;
  List<StatusChipModel> _statusChips = [];

  BranchManagerUpdateStatusViewModel({
    required this.customer,
    http.Client? client,
    TokenStorage? tokenStorage,
    BranchManagerUpdateStatusLogic? logic,
  }) : _shouldCloseClient = client == null && logic == null,
       _logic =
           logic ??
           BranchManagerUpdateStatusLogic(
             client: client,
             tokenStorage: tokenStorage,
           ) {
    _hasBeenScheduled =
        customer.hasBeenScheduled ||
        customer.status.toLowerCase() == 'scheduled' ||
        customer.status.toLowerCase() == 'completed';

    _selectedStatus = customer.status;

    if (!_hasBeenScheduled && _selectedStatus.toLowerCase() == 'completed') {
      _selectedStatus = 'New';
    } else if (_hasBeenScheduled && _selectedStatus.toLowerCase() == 'new') {
      _selectedStatus = 'Scheduled';
    }

    _notesController = TextEditingController(text: customer.notes);
    _scheduleDate =
        (customer.scheduleDate != null && customer.scheduleDate!.isNotEmpty)
        ? customer.scheduleDate!
        : formatCurrentDate();
    if (_selectedStatus.toLowerCase() == 'completed') {
      _scheduleDate = formatCurrentDate();
    }
    _documents = List<String>.from(customer.documents);
  }

  // Getters
  String get selectedStatus => _selectedStatus;
  TextEditingController get notesController => _notesController;
  String get scheduleDate => _scheduleDate;
  bool get hasBeenScheduled => _hasBeenScheduled;
  bool get isSaving => _isSaving;
  bool get isLoadingChips => _isLoadingChips;
  bool get isUploadingDocument => _isUploadingDocument;
  String? get errorMessage => _errorMessage;
  List<String> get documents => _documents;
  List<StatusChipModel> get statusChips {
    if (_hasBeenScheduled) {
      // After scheduled: remove 'New' filter chip, show 'Completed' (and Scheduled, Cancelled)
      return _statusChips.where((chip) {
        final label = chip.label.toLowerCase();
        final code = chip.code.toLowerCase();
        return label != 'new' && code != 'new';
      }).toList();
    } else {
      // When it's New: don't show 'Completed' filter chip
      return _statusChips.where((chip) {
        final label = chip.label.toLowerCase();
        final code = chip.code.toLowerCase();
        return label != 'completed' && code != 'completed';
      }).toList();
    }
  }

  List<String> get availableOptions => _statusChips.isNotEmpty
      ? statusChips.map((c) => c.label).toList()
      : getAvailableStatusOptions(hasBeenScheduled: _hasBeenScheduled);

  /// Loads status filter chips from GET /api/status.
  Future<void> loadStatusChips() async {
    _isLoadingChips = true;
    notifyListeners();

    try {
      final chips = await _logic.fetchStatusChips();
      if (chips.isNotEmpty) {
        _statusChips = chips;

        // Ensure selectedStatus uses chip.label for display
        final matchingChip = statusChips.where((c) =>
            c.label.toLowerCase().trim() == _selectedStatus.toLowerCase().trim() ||
            c.code.toLowerCase().trim() == _selectedStatus.toLowerCase().trim()).firstOrNull;
        if (matchingChip != null) {
          _selectedStatus = matchingChip.label;
        } else if (statusChips.isNotEmpty) {
          _selectedStatus = statusChips.first.label;
        }
      }
    } catch (_) {
      // Ignored
    } finally {
      _isLoadingChips = false;
      notifyListeners();
    }
  }

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

  UpdateStatusVisibility get visibility =>
      UpdateStatusVisibility(_selectedStatus);

  bool get showSchedule => visibility.showSchedule;

  void setStatus(String status) {
    final matchingChip = statusChips.where((c) =>
        c.label.toLowerCase().trim() == status.toLowerCase().trim() ||
        c.code.toLowerCase().trim() == status.toLowerCase().trim()).firstOrNull;
    final resolvedStatus = matchingChip != null ? matchingChip.label : status;

    if (_selectedStatus != resolvedStatus) {
      _selectedStatus = resolvedStatus;
      if (resolvedStatus.toLowerCase() == 'completed') {
        _scheduleDate = formatCurrentDate();
      }
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

    if (_selectedStatus.toLowerCase() == 'completed') {
      _scheduleDate = formatCurrentDate();
    }

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
          AppNotification.showStatusChange(
            context,
            status: _selectedStatus,
            customerName: customer.name,
          );
        }
        _isSaving = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = 'Failed to update status on server';
        if (context.mounted) {
          AppNotification.showError(context, _errorMessage!);
        }
        _isSaving = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Connection error';
      if (context.mounted) {
        AppNotification.showError(context, _errorMessage!);
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
