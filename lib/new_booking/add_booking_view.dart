import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/widgets/circular_back_button.dart';
import '../core/theme.dart';
import '../api/document_upload_service.dart';
import '../settings/settings_model.dart';
import 'add_booking_view_model.dart';
import 'area_view_model.dart';
import 'district_view_model.dart';
import 'lead_data.dart';
import 'widgets/area_selector_dropdown.dart';
import 'widgets/district_selector_dropdown.dart';
import 'widgets/lead_document_upload_card.dart';
import 'widgets/lead_form_card.dart';
import 'widgets/lead_labeled_row.dart';
import 'widgets/lead_stage_selector.dart';

class add_booking extends StatefulWidget {
  final LeadFormData? initialData;
  final List<String>? stages;
  final ValueChanged<LeadFormData>? onSave;
  final VoidCallback? onCancel;
  final AreaViewModel? areaViewModel;
  final DistrictViewModel? districtViewModel;
  final AddBookingViewModel? viewModel;
  final bool? isCoordinator;

  const add_booking({
    super.key,
    this.initialData,
    this.stages,
    this.onSave,
    this.onCancel,
    this.areaViewModel,
    this.districtViewModel,
    this.viewModel,
    this.isCoordinator,
  });

  @override
  State<add_booking> createState() => _add_bookingState();
}

class _add_bookingState extends State<add_booking> {
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;
  late final AddBookingViewModel _viewModel;
  late List<String> _documents;
  bool _isUploadingDocument = false;
  bool _isLocalViewModel = false;

  late List<String> _stages;
  late int _selectedStageIndex;
  late bool _isCoordinator;
  String? _selectedDistrict;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? initialLeadData;
    _nameController = TextEditingController(text: data.name);
    _mobileController = TextEditingController(text: data.mobile);
    _addressController = TextEditingController(text: data.address);
    _notesController = TextEditingController(text: data.notes);
    _documents = List<String>.from(data.documents);

    _stages = widget.stages ?? defaultLeadStages;
    final stageIdx = _stages.indexOf(data.stage);
    _selectedStageIndex = stageIdx != -1 ? stageIdx : 0;

    _isCoordinator = widget.isCoordinator ?? false;
    _selectedDistrict = data.district ?? defaultHardcodedDistricts.first;

    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _isLocalViewModel = false;
    } else {
      _viewModel = AddBookingViewModel(
        areaViewModel: widget.areaViewModel,
        districtViewModel: widget.districtViewModel,
      );
      _isLocalViewModel = true;
    }

    if (data.district != null && data.district!.isNotEmpty) {
      _viewModel.districtViewModel.selectDistrictByName(data.district);
    }

    if (widget.isCoordinator != null) {
      if (_isCoordinator) {
        _viewModel.areaViewModel.isCoordinator = true;
        final dId = _viewModel.districtViewModel.selectedDistrictId;
        _viewModel.areaViewModel.fetchAreas(isCoordinator: true, districtId: dId);
        _viewModel.districtViewModel.fetchDistricts();
      } else {
        _viewModel.areaViewModel.isCoordinator = false;
        _viewModel.areaViewModel.fetchAreas(isCoordinator: false);
      }
    } else {
      _loadCoordinatorRole();
    }

    if (data.areaId != null) {
      _viewModel.areaViewModel.selectAreaById(data.areaId);
    }
  }

  Future<void> _loadCoordinatorRole() async {
    final user = await UserProfileData.loadUser();
    if (mounted && user != null) {
      final isCoord = user.roleId == 2;
      setState(() {
        _isCoordinator = isCoord;
        _viewModel.areaViewModel.isCoordinator = isCoord;
        if (user.districtName != null && user.districtName!.isNotEmpty) {
          _selectedDistrict = user.districtName;
          _viewModel.districtViewModel.selectDistrictByName(user.districtName);
        }
      });
      if (isCoord) {
        final dId = _viewModel.districtViewModel.selectedDistrictId;
        _viewModel.districtViewModel.fetchDistricts();
        _viewModel.areaViewModel.fetchAreas(
          isCoordinator: true,
          districtId: dId,
        );
      } else {
        _viewModel.areaViewModel.fetchAreas(isCoordinator: false);
      }
    } else if (mounted) {
      _viewModel.areaViewModel.fetchAreas(isCoordinator: false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    if (_isLocalViewModel) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    final selectedStage =
        (_selectedStageIndex >= 0 && _selectedStageIndex < _stages.length)
        ? _stages[_selectedStageIndex]
        : (_stages.isNotEmpty ? _stages[0] : 'NEW');

    final districtVm = _viewModel.districtViewModel;
    final selectedDistrictItem = districtVm.selectedDistrict;
    final effectiveDistrictId = _isCoordinator
        ? (selectedDistrictItem != null && selectedDistrictItem.id > 0
            ? selectedDistrictItem.id
            : null)
        : null;
    final effectiveDistrictName = _isCoordinator
        ? (_selectedDistrict ?? selectedDistrictItem?.name)
        : null;

    final result = LeadFormData(
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
      stage: selectedStage,
      areaId: _viewModel.areaViewModel.selectedAreaId,
      areaName: _viewModel.areaViewModel.selectedAreaName,
      districtId: effectiveDistrictId,
      districtName: effectiveDistrictName,
      district: effectiveDistrictName,
      documents: _documents,
    );

    final saveResult = await _viewModel.saveBooking(result);

    if (!mounted) return;

    if (saveResult.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Booking saved successfully!',
            style: TextStyle(fontFamily: 'Helvetica Neue'),
          ),
          backgroundColor: AppColors.whatsappGreen,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );

      if (widget.onSave != null) {
        widget.onSave!(result);
      } else {
        Navigator.of(context).pop(result);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saveResult.errorMessage ?? 'Failed to save booking',
            style: const TextStyle(fontFamily: 'Helvetica Neue'),
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handlePickDocuments() async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx', 'doc', 'png', 'jpg', 'jpeg'],
      );

      if (files.isNotEmpty && mounted) {
        setState(() => _isUploadingDocument = true);
        final uploadService = DocumentUploadService();

        for (final file in files) {
          List<int>? bytes;
          try {
            bytes = await file.readAsBytes();
          } catch (_) {}

          final uploadedUrl = await uploadService.uploadFile(
            fileName: file.name,
            bytes: bytes,
            filePath: file.path,
          );

          if (!mounted) break;

          if (uploadedUrl != null) {
            setState(() {
              if (!_documents.contains(uploadedUrl)) {
                _documents.add(uploadedUrl);
              }
            });
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to upload ${file.name}. Please try again.',
                  style: const TextStyle(fontFamily: 'Helvetica Neue'),
                ),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('FilePicker error: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploadingDocument = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppDarkColors.textPrimary
        : const Color(0xFF0F172A);
    final subtitleTextColor = isDark
        ? AppDarkColors.textSubtitle
        : const Color(0xFF475569);
    final placeholderColor = isDark
        ? AppDarkColors.textPlaceholder
        : const Color(0xFF94A3B8);
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 58,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Center(child: CircularBackButton(onBack: _handleCancel)),
        ),
        title: Text(
          'New booking',
          style: TextStyle(
            color: primaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        titleSpacing: 8,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Name Card
              LeadFormCard(
                child: TextField(
                  controller: _nameController,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: primaryTextColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Full Name',
                    hintStyle: TextStyle(color: placeholderColor),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 2. Mobile Card
              LeadFormCard(
                child: LeadLabeledRow(
                  label: 'Mobile',
                  controller: _mobileController,
                  hintText: 'Mobile number',
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+\- ]')),
                  ],
                  maxLength: 15,
                ),
              ),
              const SizedBox(height: 14),

              // 3. Address & Notes Card
              LeadFormCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LeadLabeledRow(
                      label: 'Address',
                      controller: _addressController,
                      hintText: 'Address',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(
                        height: 1,
                        thickness: 0.6,
                        color: isDark
                            ? AppDarkColors.divider
                            : const Color(0xFFF1F5F9),
                      ),
                    ),
                    Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: primaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppDarkColors.textPrimary
                            : const Color(0xFF334155),
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Add client requirements, background, or preferred contact time...',
                        hintStyle: TextStyle(
                          color: placeholderColor,
                          fontSize: 13.5,
                          height: 1.4,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              // 4. District Selector Card (for Coordinator role)
              if (_isCoordinator) ...[
                ListenableBuilder(
                  listenable: _viewModel.districtViewModel,
                  builder: (context, _) {
                    final districtVm = _viewModel.districtViewModel;
                    final currentSelected =
                        _selectedDistrict ??
                        districtVm.selectedDistrictName ??
                        districtVm.districts.firstOrNull?.name;

                    return DistrictSelectorDropdown(
                      selectedDistrict: currentSelected,
                      districtItems: districtVm.districts,
                      isLoading: districtVm.isLoading,
                      onDistrictSelected: (district) {
                        setState(() {
                          _selectedDistrict = district;
                        });
                        districtVm.selectDistrictByName(district);
                        final selectedItem = districtVm.selectedDistrict;
                        if (selectedItem != null && selectedItem.id > 0) {
                          _viewModel.areaViewModel.fetchAreas(
                            isCoordinator: true,
                            districtId: selectedItem.id,
                          );
                        }
                      },
                      onDistrictItemSelected: (item) {
                        setState(() {
                          _selectedDistrict = item.name;
                        });
                        districtVm.selectDistrict(item);
                        if (item.id > 0) {
                          _viewModel.areaViewModel.fetchAreas(
                            isCoordinator: true,
                            districtId: item.id,
                          );
                        }
                      },
                    );
                  },
                ),
                const SizedBox(height: 14),
              ],

              // 5. Area Selector Card
              AreaSelectorDropdown(viewModel: _viewModel.areaViewModel),
              const SizedBox(height: 14),

              // 5. Attach Documents Card
              LeadDocumentUploadCard(
                documents: _documents,
                isUploading: _isUploadingDocument,
                onTap: _isUploadingDocument ? null : _handlePickDocuments,
                onRemove: (doc) {
                  setState(() {
                    _documents.remove(doc);
                  });
                },
              ),
              const SizedBox(height: 22),

              // 6. Lead Stage Selector
              LeadStageSelector(
                stages: _stages,
                selectedIndex: _selectedStageIndex,
                onStageSelected: (index) {
                  setState(() {
                    _selectedStageIndex = index;
                  });
                },
              ),
              const SizedBox(height: 28),

              // 5. Save Lead Button
              ListenableBuilder(
                listenable: _viewModel,
                builder: (context, _) {
                  return SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _viewModel.isSubmitting ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.whatsappGreen,
                        foregroundColor: isDark
                            ? const Color(0xFF0B141B)
                            : Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _viewModel.isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontFamily: 'Helvetica Neue',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 14),

              // 6. Cancel Button (pure text with no background)
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _handleCancel,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: subtitleTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
