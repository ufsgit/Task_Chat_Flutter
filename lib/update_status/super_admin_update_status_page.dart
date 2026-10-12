import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../customer_details/customer_details_data.dart';
import '../today/today_data.dart';
import 'update_status_data.dart';
import 'widgets/branch_manager_field_card.dart';
import 'widgets/group_field_card.dart';
import 'widgets/location_field_card.dart';
import 'widgets/notes_field_card.dart';
import 'widgets/schedule_field_card.dart';
import 'widgets/status_selector_chips.dart';
import 'widgets/update_status_header.dart';

/// Screen allowing Super Admin to update the status, notes, schedule,
/// location, branch manager assignment, and group for a lead.
class SuperAdminUpdateStatusPage extends StatefulWidget {
  final CustomerDetailsData customer;

  const SuperAdminUpdateStatusPage({
    super.key,
    required this.customer,
  });

  @override
  State<SuperAdminUpdateStatusPage> createState() =>
      _SuperAdminUpdateStatusPageState();
}

class _SuperAdminUpdateStatusPageState
    extends State<SuperAdminUpdateStatusPage> {
  late String _selectedStatus;
  late TextEditingController _notesController;
  late String _scheduleDate;
  late String _selectedLocation;
  late String _selectedBranchManager;
  late String _selectedGroup;

  @override
  void initState() {
    super.initState();
    _selectedStatus = defaultSuperAdminUpdateStatusFormData.defaultStatus;
    _notesController = TextEditingController(
      text: defaultSuperAdminUpdateStatusFormData.defaultNotes,
    );
    _scheduleDate =
        defaultSuperAdminUpdateStatusFormData.defaultScheduleDate;
    _selectedLocation =
        defaultSuperAdminUpdateStatusFormData.defaultLocation;
    _selectedBranchManager =
        defaultSuperAdminUpdateStatusFormData.defaultBranchManager;
    _selectedGroup = defaultSuperAdminUpdateStatusFormData.defaultGroup;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // 1. Update status in todayChatItems / superAdminChatItems
    updateChatItemStatus(
      customerName: widget.customer.name,
      newStatus: _selectedStatus,
      newLocation: _selectedLocation,
    );

    // 2. Feedback SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Status updated to $_selectedStatus for ${widget.customer.name} (Assigned: $_selectedBranchManager)',
        ),
        backgroundColor: AppColors.primaryGreen,
        duration: const Duration(seconds: 1),
      ),
    );

    // 3. Return the new status to CustomerDetailsPage
    Navigator.of(context).pop(_selectedStatus);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Header with back button, avatar, and Customer Name
              UpdateStatusHeader(
                customerName: widget.customer.name,
                onBack: () => Navigator.of(context).pop(),
              ),

              const SizedBox(height: 20),

              // 2. Select Status Section (Completed, New, Scheduled, Cancelled)
              const Text(
                'Select Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              StatusSelectorChips(
                selectedStatus: _selectedStatus,
                options: availableSuperAdminStatusOptions,
                onStatusSelected: (status) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
              ),

              const SizedBox(height: 20),

              // 3. Notes Section
              NotesFieldCard(controller: _notesController),

              const SizedBox(height: 20),

              // 4. Schedule Section
              ScheduleFieldCard(
                dateText: _scheduleDate,
                onDateChanged: (newDate) {
                  setState(() {
                    _scheduleDate = newDate;
                  });
                },
              ),

              const SizedBox(height: 20),

              // 5. Location & Branch Manager side-by-side
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: LocationFieldCard(
                      selectedLocation: _selectedLocation,
                      onLocationChanged: (val) {
                        setState(() {
                          _selectedLocation = val;
                        });
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BranchManagerFieldCard(
                      selectedManager: _selectedBranchManager,
                      onManagerChanged: (val) {
                        setState(() {
                          _selectedBranchManager = val;
                        });
                      },
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 6. Select Group Section
              GroupFieldCard(
                selectedGroup: _selectedGroup,
                onGroupChanged: (val) {
                  setState(() {
                    _selectedGroup = val;
                  });
                },
              ),

              const SizedBox(height: 24),

              // 7. Save Button
              _buildSaveButton(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.whatsappGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
