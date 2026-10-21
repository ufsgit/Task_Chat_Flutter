import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../customer_details/customer_details_model.dart';
import '../today/today_view_model.dart';
import 'update_status_data.dart';
import 'widgets/attach_documents_card.dart';
import 'widgets/notes_field_card.dart';
import 'widgets/schedule_field_card.dart';
import 'widgets/status_selector_chips.dart';
import 'widgets/update_status_header.dart';

/// Screen allowing users to update the status, schedule,
/// and notes for a customer lead.
/// Per requirements:
/// - Location field is removed.
/// - All statuses use the same: Notes and Calendar only.
/// - "Completed" option only shows after the lead has been scheduled once.
class UpdateStatusPage extends StatefulWidget {
  final CustomerDetailsData customer;

  const UpdateStatusPage({super.key, required this.customer});

  @override
  State<UpdateStatusPage> createState() => _UpdateStatusPageState();
}

class _UpdateStatusPageState extends State<UpdateStatusPage> {
  late String _selectedStatus;
  late TextEditingController _notesController;
  late String _scheduleDate;
  late bool _hasBeenScheduled;

  @override
  void initState() {
    super.initState();
    _hasBeenScheduled = widget.customer.hasBeenScheduled ||
        widget.customer.status.toLowerCase() == 'scheduled' ||
        widget.customer.status.toLowerCase() == 'completed';

    _selectedStatus = widget.customer.status.toLowerCase() == 'new'
        ? 'Scheduled'
        : widget.customer.status;

    if (!_hasBeenScheduled && _selectedStatus.toLowerCase() == 'completed') {
      _selectedStatus = 'Scheduled';
    }

    _notesController = TextEditingController(text: '');
    _scheduleDate = defaultUpdateStatusFormData.defaultScheduleDate;
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
    final availableOptions = getAvailableStatusOptions(
      hasBeenScheduled: _hasBeenScheduled,
    );
    final visibility = UpdateStatusVisibility(_selectedStatus);
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              Text(
                'Select Status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppDarkColors.textPrimary : AppColors.textPrimary,
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

              // 3. Schedule (Calendar) Section (hidden when Cancelled)
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

              // 4. Notes Section (put second)
              NotesFieldCard(controller: _notesController),

              const SizedBox(height: 20),

              // 5. Attach Documents Section
              const AttachDocumentsCard(),

              const SizedBox(height: 24),

              // 6. Save Button
              _buildSaveButton(isDark),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    final fgColor = isDark ? const Color(0xFF0B141B) : Colors.white;

    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _handleSave,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.whatsappGreen,
          foregroundColor: fgColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check, size: 20, color: fgColor),
            const SizedBox(width: 8),
            Text(
              'Save',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
