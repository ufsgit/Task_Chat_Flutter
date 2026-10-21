import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_filter_chip.dart';

/// Modal bottom sheet widget for filtering leads by Status and Branch Manager
/// on the Coordinator page.
class CoordinatorFilterBottomSheet extends StatefulWidget {
  final String selectedStatus;
  final String selectedBranchManager;
  final List<String> statusOptions;
  final List<String> branchManagerOptions;
  final void Function(String status, String branchManager) onApply;
  final VoidCallback onReset;

  const CoordinatorFilterBottomSheet({
    super.key,
    required this.selectedStatus,
    required this.selectedBranchManager,
    required this.statusOptions,
    required this.branchManagerOptions,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<CoordinatorFilterBottomSheet> createState() =>
      _CoordinatorFilterBottomSheetState();
}

/// Backward compatibility alias for CoordinatorFilterBottomSheet.
typedef SuperAdminFilterBottomSheet = CoordinatorFilterBottomSheet;

class _CoordinatorFilterBottomSheetState
    extends State<CoordinatorFilterBottomSheet> {
  late String _tempStatus;
  late String _tempBranchManager;

  @override
  void initState() {
    super.initState();
    _tempStatus = widget.selectedStatus;
    _tempBranchManager = widget.selectedBranchManager;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _tempStatus = 'All';
                      _tempBranchManager = 'All';
                    });
                    widget.onReset();
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: AppColors.brandGreen,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.divider, height: 20, thickness: 0.6),

            // Section 1: Status
            const Text(
              'Status',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.statusOptions.map((status) {
                final isSelected = _tempStatus == status;
                return AppFilterChip(
                  label: status,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _tempStatus = status;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 18),

            // Section 2: Branch Manager
            const Text(
              'Branch Manager',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.branchManagerOptions.map((manager) {
                final isSelected = _tempBranchManager == manager;
                return AppFilterChip(
                  label: manager,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _tempBranchManager = manager;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_tempStatus, _tempBranchManager);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
