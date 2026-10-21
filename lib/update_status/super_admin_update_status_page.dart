import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../customer_details/customer_details_model.dart';
import '../today/today_view_model.dart';
import 'update_status_data.dart';
import 'widgets/attach_documents_card.dart';
import 'widgets/branch_manager_field_card.dart';
import 'widgets/notes_field_card.dart';
import 'widgets/schedule_field_card.dart';
import 'widgets/status_selector_chips.dart';
import 'widgets/update_status_header.dart';

/// Screen allowing Coordinator (formerly Super Admin) to update the status, notes, schedule,
/// and assigned branch manager for a customer lead.
/// Per requirements:
/// - Location field is removed.
/// - Notes and Calendar used for updating status.
/// - "Completed" option only shows after the lead has been scheduled once.
/// - Option to change branch manager for coordinator.
class CoordinatorUpdateStatusPage extends StatefulWidget {
  final CustomerDetailsData customer;

  const CoordinatorUpdateStatusPage({super.key, required this.customer});

  @override
  State<CoordinatorUpdateStatusPage> createState() =>
      _CoordinatorUpdateStatusPageState();
}

/// Backward compatibility alias for CoordinatorUpdateStatusPage.
typedef SuperAdminUpdateStatusPage = CoordinatorUpdateStatusPage;

class _CoordinatorUpdateStatusPageState
    extends State<CoordinatorUpdateStatusPage> {
  late String _selectedStatus;
  late TextEditingController _notesController;
  late String _scheduleDate;
  late String _selectedBranchManager;
  late bool _hasBeenScheduled;

  @override
  void initState() {
    super.initState();
    _hasBeenScheduled =
        widget.customer.hasBeenScheduled ||
        widget.customer.status.toLowerCase() == 'scheduled' ||
        widget.customer.status.toLowerCase() == 'completed';

    _selectedStatus = widget.customer.status.toLowerCase() == 'new'
        ? 'Scheduled'
        : widget.customer.status;

    if (!_hasBeenScheduled && _selectedStatus.toLowerCase() == 'completed') {
      _selectedStatus = 'Scheduled';
    }

    _notesController = TextEditingController(text: '');
    _scheduleDate = defaultCoordinatorUpdateStatusFormData.defaultScheduleDate;
    _selectedBranchManager =
        defaultCoordinatorUpdateStatusFormData.defaultBranchManager;
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
    final availableOptions = getAvailableStatusOptions(
      hasBeenScheduled: _hasBeenScheduled,
    );
    final visibility = UpdateStatusVisibility(_selectedStatus);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

              // 2. Select Status Section
              // "Completed" only shows after the lead has been scheduled once
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
                options: availableOptions,
                onStatusSelected: (status) {
                  setState(() {
                    _selectedStatus = status;
                  });
                },
              ),

              const SizedBox(height: 20),

              // 3. Branch Manager Selection Card
              BranchManagerFieldCard(
                selectedManager: _selectedBranchManager,
                onManagerChanged: (val) {
                  setState(() {
                    _selectedBranchManager = val;
                  });
                },
              ),

              const SizedBox(height: 20),

              // 4. Schedule (Calendar) Section (hidden when Cancelled)
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

              // 5. Notes Section (put second)
              NotesFieldCard(controller: _notesController),

              const SizedBox(height: 20),

              // 6. Attach Documents Section
              const AttachDocumentsCard(),

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
            Icon(Icons.check, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Save',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
