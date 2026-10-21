import 'package:flutter/material.dart';
import '../core/circular_back_button.dart';
import '../core/theme.dart';
import 'lead_data.dart';
import 'widgets/lead_form_card.dart';
import 'widgets/lead_labeled_row.dart';
import 'widgets/lead_stage_selector.dart';
import 'widgets/lead_document_upload_card.dart';

class add_booking extends StatefulWidget {
  final LeadFormData? initialData;
  final List<String>? stages;
  final ValueChanged<LeadFormData>? onSave;
  final VoidCallback? onCancel;

  const add_booking({
    super.key,
    this.initialData,
    this.stages,
    this.onSave,
    this.onCancel,
  });

  @override
  State<add_booking> createState() => _add_bookingState();
}

class _add_bookingState extends State<add_booking> {
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  late final TextEditingController _addressController;
  late final TextEditingController _notesController;

  late List<String> _stages;
  late int _selectedStageIndex;

  @override
  void initState() {
    super.initState();
    final data = widget.initialData ?? initialLeadData;
    _nameController = TextEditingController(text: data.name);
    _mobileController = TextEditingController(text: data.mobile);
    _addressController = TextEditingController(text: data.address);
    _notesController = TextEditingController(text: data.notes);

    _stages = widget.stages ?? defaultLeadStages;
    final stageIdx = _stages.indexOf(data.stage);
    _selectedStageIndex = stageIdx != -1 ? stageIdx : 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    final selectedStage =
        (_selectedStageIndex >= 0 && _selectedStageIndex < _stages.length)
        ? _stages[_selectedStageIndex]
        : (_stages.isNotEmpty ? _stages[0] : 'New Lead');

    final result = LeadFormData(
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
      stage: selectedStage,
    );

    if (widget.onSave != null) {
      widget.onSave!(result);
    } else {
      Navigator.of(context).pop(result);
    }
  }

  void _handleCancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      Navigator.of(context).pop();
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
              const SizedBox(height: 14),

              // 4. Attach Documents Card
              const LeadDocumentUploadCard(),
              const SizedBox(height: 22),

              // 5. Lead Stage Selector
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
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleSave,
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
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
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
