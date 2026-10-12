import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'lead_data.dart';
import 'widgets/lead_form_card.dart';
import 'widgets/lead_labeled_row.dart';
import 'widgets/lead_stage_selector.dart';

class CreateLeadPage extends StatefulWidget {
  final LeadFormData? initialData;
  final List<String>? stages;
  final ValueChanged<LeadFormData>? onSave;
  final VoidCallback? onCancel;

  const CreateLeadPage({
    super.key,
    this.initialData,
    this.stages,
    this.onSave,
    this.onCancel,
  });

  @override
  State<CreateLeadPage> createState() => _CreateLeadPageState();
}

class _CreateLeadPageState extends State<CreateLeadPage> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          onPressed: _handleCancel,
        ),
        title: const Text(
          'Create New Lead',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        titleSpacing: 0,
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
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Full Name',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8)),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Divider(
                        height: 1,
                        thickness: 0.8,
                        color: Color(0xFFF1F5F9),
                      ),
                    ),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notesController,
                      maxLines: 4,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF334155),
                      ),
                      decoration: const InputDecoration(
                        hintText:
                            'Add client requirements, background, or preferred contact time...',
                        hintStyle: TextStyle(
                          color: Color(0xFF94A3B8),
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
              const SizedBox(height: 22),

              // 4. Lead Stage Selector
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
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
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
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569),
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
