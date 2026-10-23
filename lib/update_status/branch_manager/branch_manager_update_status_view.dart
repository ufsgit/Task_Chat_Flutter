import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/theme.dart';
import '../../customer_details/customer_details_model.dart';
import '../../login_page/token_storage.dart';
import '../widgets/attach_documents_card.dart';
import '../widgets/notes_field_card.dart';
import '../widgets/schedule_field_card.dart';
import '../widgets/status_selector_chips.dart';
import '../widgets/update_status_header.dart';
import 'branch_manager_update_status_view_model.dart';

/// Screen allowing Branch Managers / staff to update the status, schedule,
/// and notes for a customer lead using MVVM/MVVC architecture.
class BranchManagerUpdateStatusView extends StatefulWidget {
  final CustomerDetailsData customer;
  final http.Client? client;
  final TokenStorage? tokenStorage;
  final BranchManagerUpdateStatusViewModel? viewModel;

  const BranchManagerUpdateStatusView({
    super.key,
    required this.customer,
    this.client,
    this.tokenStorage,
    this.viewModel,
  });

  @override
  State<BranchManagerUpdateStatusView> createState() =>
      _BranchManagerUpdateStatusViewState();
}

/// Backward compatibility alias for BranchManagerUpdateStatusView
typedef UpdateStatusView = BranchManagerUpdateStatusView;

/// Backward compatibility alias for UpdateStatusPage
typedef UpdateStatusPage = BranchManagerUpdateStatusView;

class _BranchManagerUpdateStatusViewState
    extends State<BranchManagerUpdateStatusView> {
  late final BranchManagerUpdateStatusViewModel _viewModel;
  late final bool _internalVm;

  @override
  void initState() {
    super.initState();
    if (widget.viewModel != null) {
      _viewModel = widget.viewModel!;
      _internalVm = false;
    } else {
      _viewModel = BranchManagerUpdateStatusViewModel(
        customer: widget.customer,
        client: widget.client,
        tokenStorage: widget.tokenStorage,
      );
      _internalVm = true;
    }
  }

  @override
  void dispose() {
    if (_internalVm) {
      _viewModel.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    final success = await _viewModel.saveStatus(context);
    if (success && mounted) {
      Navigator.of(context).pop(_viewModel.selectedStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
                  Text(
                    'Select Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  StatusSelectorChips(
                    selectedStatus: _viewModel.selectedStatus,
                    options: _viewModel.availableOptions,
                    onStatusSelected: _viewModel.setStatus,
                  ),

                  const SizedBox(height: 20),

                  // 3. Schedule (Calendar) Section (hidden when Cancelled)
                  if (_viewModel.showSchedule) ...[
                    ScheduleFieldCard(
                      dateText: _viewModel.scheduleDate,
                      onDateChanged: _viewModel.setScheduleDate,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 4. Notes Section (read-only per requirements)
                  NotesFieldCard(controller: _viewModel.notesController),

                  const SizedBox(height: 20),

                  // 5. Attach Documents Section
                  const AttachDocumentsCard(),

                  const SizedBox(height: 24),

                  // 6. Save Button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _viewModel.isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.whatsappGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: _viewModel.isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 20, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Save',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
