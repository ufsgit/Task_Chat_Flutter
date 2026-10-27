import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';
import '../../customer_details/customer_details_model.dart';
import '../../login_page/token_storage.dart';
import '../models/status_chip_model.dart';
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
  bool _isLoadingManagers = false;
  bool _isLoadingChips = false;
  bool _isUploadingDocument = false;
  String? _errorMessage;
  List<BranchHeadUser> _branchManagers = [];
  List<StatusChipModel> _statusChips = [];
  late List<String> _documents;

  CoordinatorUpdateStatusViewModel({
    required this.customer,
    http.Client? client,
    TokenStorage? tokenStorage,
    CoordinatorUpdateStatusLogic? logic,
    bool autoLoadManagers = false,
    String? initialBranchManager,
  }) : _shouldCloseClient = client == null && logic == null,
       _logic =
           logic ??
           CoordinatorUpdateStatusLogic(
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
        : '10/24/2024';
    _documents = List<String>.from(customer.documents);
    final resolvedInitialManager =
        (initialBranchManager != null && initialBranchManager.trim().isNotEmpty)
        ? initialBranchManager.trim()
        : ((customer.branchHeadName != null &&
                  customer.branchHeadName!.trim().isNotEmpty)
              ? customer.branchHeadName!.trim()
              : null);

    _selectedBranchManager =
        resolvedInitialManager ?? availableBranchManagers.first;

    if (autoLoadManagers) {
      loadBranchManagers();
    }
  }

  // Getters
  String get selectedStatus => _selectedStatus;
  TextEditingController get notesController => _notesController;
  String get scheduleDate => _scheduleDate;
  String get selectedBranchManager => _selectedBranchManager;
  bool get hasBeenScheduled => _hasBeenScheduled;
  bool get isSaving => _isSaving;
  bool get isLoadingManagers => _isLoadingManagers;
  bool get isLoadingChips => _isLoadingChips;
  bool get isUploadingDocument => _isUploadingDocument;
  String? get errorMessage => _errorMessage;
  List<BranchHeadUser> get branchManagers => _branchManagers;
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

  List<String> get availableManagers {
    final list = _branchManagers.isNotEmpty
        ? _branchManagers.map((m) => m.name).toList()
        : List<String>.from(availableBranchManagers);
    if (_selectedBranchManager.isNotEmpty &&
        !list.contains(_selectedBranchManager)) {
      list.insert(0, _selectedBranchManager);
    }
    return list;
  }

  /// Fetches branch head managers from API and updates available options.
  Future<void> loadBranchManagers() async {
    _isLoadingManagers = true;
    notifyListeners();

    try {
      final managers = await _logic.fetchBranchManagers();
      if (managers.isNotEmpty) {
        _branchManagers = managers;
        final names = _branchManagers.map((m) => m.name).toList();

        // If customer has an assigned branch head, match it
        BranchHeadUser? matched;
        if (customer.branchHeadId != null) {
          matched = _branchManagers
              .where((m) => m.id == customer.branchHeadId)
              .firstOrNull;
        }

        final targetName =
            (customer.branchHeadName != null &&
                customer.branchHeadName!.trim().isNotEmpty)
            ? customer.branchHeadName!.trim()
            : null;

        if (matched == null && targetName != null) {
          matched = _branchManagers
              .where(
                (m) =>
                    m.name.toLowerCase().trim() == targetName.toLowerCase() ||
                    m.username.toLowerCase().trim() == targetName.toLowerCase(),
              )
              .firstOrNull;
        }

        if (matched != null) {
          _selectedBranchManager = matched.name;
        } else if (targetName != null) {
          _selectedBranchManager = targetName;
        } else if (!names.contains(_selectedBranchManager)) {
          _selectedBranchManager = names.first;
        }
      }
    } catch (_) {
      // Ignored - fallback to availableBranchManagers
    } finally {
      _isLoadingManagers = false;
      notifyListeners();
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

        // Ensure selectedStatus is valid among the visible chips
        final visibleLabels =
            statusChips.map((c) => c.label.toLowerCase()).toList();
        if (!visibleLabels.contains(_selectedStatus.toLowerCase())) {
          _selectedStatus = statusChips.isNotEmpty
              ? statusChips.first.label
              : _selectedStatus;
        }
      }
    } catch (_) {
      // Ignored
    } finally {
      _isLoadingChips = false;
      notifyListeners();
    }
  }

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

  BranchHeadUser? get selectedBranchHead {
    if (_branchManagers.isEmpty) return null;
    if (customer.branchHeadId != null) {
      final byId = _branchManagers
          .where((m) => m.id == customer.branchHeadId)
          .firstOrNull;
      if (byId != null &&
          byId.name.toLowerCase().trim() ==
              _selectedBranchManager.toLowerCase().trim()) {
        return byId;
      }
    }
    return _branchManagers
        .where(
          (m) =>
              m.name.toLowerCase().trim() ==
                  _selectedBranchManager.toLowerCase().trim() ||
              m.username.toLowerCase().trim() ==
                  _selectedBranchManager.toLowerCase().trim(),
        )
        .firstOrNull;
  }

  /// Saves the status update to the backend API and shows user feedback.
  Future<bool> saveStatus(BuildContext context) async {
    if (_isSaving) return false;

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final selectedBm = selectedBranchHead;
      final bmId = selectedBm?.id ?? customer.branchHeadId;
      final bmName = selectedBm?.name ?? _selectedBranchManager;
      final districtId = selectedBm?.districtId;
      final districtName = selectedBm?.districtName;
      final success = await _logic.submitStatusUpdate(
        customer: customer,
        status: _selectedStatus,
        scheduleDate: _scheduleDate,
        notes: _notesController.text,
        branchManager: _selectedBranchManager,
        branchManagerId: bmId,
        branchManagerName: bmName,
        districtId: districtId,
        districtName: districtName,
        documents: _documents,
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
