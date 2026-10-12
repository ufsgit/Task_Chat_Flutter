import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../customer_details/customer_details_data.dart';
import '../today/today_data.dart';
import 'update_status_data.dart';
import 'widgets/group_field_card.dart';
import 'widgets/location_field_card.dart';
import 'widgets/notes_field_card.dart';
import 'widgets/schedule_field_card.dart';
import 'widgets/status_selector_chips.dart';
import 'widgets/update_status_header.dart';

/// Screen allowing users to update the status, schedule, location,
/// and notes for a customer lead with dynamic field visibility rules.
class UpdateStatusPage extends StatefulWidget {
  final CustomerDetailsData customer;

  const UpdateStatusPage({
    super.key,
    required this.customer,
  });

  @override
  State<UpdateStatusPage> createState() => _UpdateStatusPageState();
}

class _UpdateStatusPageState extends State<UpdateStatusPage> {
  late String _selectedStatus;
  late TextEditingController _notesController;
  late String _scheduleDate;
  String _selectedLocation = 'Home';
  String _selectedGroup = 'Personal Care';

  @override
  void initState() {
    super.initState();
    _selectedStatus = defaultUpdateStatusFormData.defaultStatus;
    _notesController = TextEditingController(
      text: defaultUpdateStatusFormData.defaultNotes,
    );
    _scheduleDate = defaultUpdateStatusFormData.defaultScheduleDate;
    _selectedLocation = defaultUpdateStatusFormData.defaultLocation;
    _selectedGroup = defaultUpdateStatusFormData.defaultGroup;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSave() {
    // 1. Update status in todayChatItems
    updateChatItemStatus(
      customerName: widget.customer.name,
      newStatus: _selectedStatus,
      newLocation: _selectedLocation,
    );

    // 2. Feedback SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Status updated to $_selectedStatus for ${widget.customer.name}',
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
    final visibility = UpdateStatusVisibility(_selectedStatus);

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

              // 2. Select Status Section (Completed, Scheduled, Cancelled)
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
                onStatusSelected: (status) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
              ),

              const SizedBox(height: 20),

              // 3. Dynamic Fields based on status:
              // - Completed: Only Schedule (Calendar) is shown
              // - Cancelled: Only Notes is shown
              // - Scheduled: All fields (Notes, Location, Group, Schedule) are shown
              if (visibility.showNotes) ...[
                NotesFieldCard(controller: _notesController),
                const SizedBox(height: 20),
              ],

              if (visibility.showLocation) ...[
                LocationFieldCard(
                  selectedLocation: _selectedLocation,
                  onLocationChanged: (val) {
                    setState(() {
                      _selectedLocation = val;
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],

              if (visibility.showGroup) ...[
                GroupFieldCard(
                  selectedGroup: _selectedGroup,
                  onGroupChanged: (val) {
                    setState(() {
                      _selectedGroup = val;
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],

              if (visibility.showSchedule) ...[
                ScheduleFieldCard(
                  dateText: _scheduleDate,
                  onDateChanged: (newDate) {
                    setState(() {
                      _scheduleDate = newDate;
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],

              const SizedBox(height: 8),

              // 4. Save Button
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
