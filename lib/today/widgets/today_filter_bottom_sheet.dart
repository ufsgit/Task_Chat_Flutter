import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/widgets/app_filter_chip.dart';

/// Modal bottom sheet widget for filtering leads and tasks by Status on the Today page.
class TodayFilterBottomSheet extends StatefulWidget {
  final String selectedStatus;
  final List<String> statusOptions;
  final void Function(String status) onApply;
  final VoidCallback? onReset;

  const TodayFilterBottomSheet({
    super.key,
    required this.selectedStatus,
    required this.statusOptions,
    required this.onApply,
    this.onReset,
  });

  @override
  State<TodayFilterBottomSheet> createState() => _TodayFilterBottomSheetState();
}

class _TodayFilterBottomSheetState extends State<TodayFilterBottomSheet> {
  late String _tempStatus;

  @override
  void initState() {
    super.initState();
    _tempStatus = widget.selectedStatus;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark
        ? AppDarkColors.textPrimary
        : AppColors.textPrimary;
    final subtitleTextColor = isDark
        ? AppDarkColors.textSubtitle
        : AppColors.textSecondary;
    final dividerColor = isDark ? AppDarkColors.divider : AppColors.divider;
    final handleColor = isDark ? Colors.white24 : const Color(0xFFCBD5E1);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
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
                  color: handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter by Status',
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor,
                  ),
                ),
              ],
            ),
            Divider(color: dividerColor, height: 20, thickness: 0.6),

            // Status Section
            Text(
              'Status',
              style: TextStyle(
                fontFamily: 'Helvetica Neue',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: subtitleTextColor,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.start,
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

            const SizedBox(height: 24),

            // Apply Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  widget.onApply(_tempStatus);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.whatsappGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Filter',
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
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
