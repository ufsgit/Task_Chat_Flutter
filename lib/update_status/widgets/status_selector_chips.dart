import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../update_status_data.dart';

/// Reusable status chip selector for Completed, Scheduled, and Cancelled.
/// Notice: The 'New' option has been completely removed per requirements.
class StatusSelectorChips extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;
  final List<String>? options;

  const StatusSelectorChips({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
    this.options,
  });

  @override
  Widget build(BuildContext context) {
    final statusList = options ?? availableStatusOptions;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: statusList.map((status) {
        final isSelected = selectedStatus.toLowerCase() == status.toLowerCase();

        Color bgColor;
        Color textColor;
        Color borderColor;

        final unselectedBg = isDark ? AppDarkColors.surfaceCard : Colors.white;
        final unselectedBorder = isDark
            ? AppDarkColors.border
            : const Color(0xFFCBD5E1);

        final normalized = status.toLowerCase();
        if (normalized == 'completed') {
          bgColor = isSelected ? AppColors.whatsappGreen : unselectedBg;
          textColor = isSelected
              ? (isDark ? const Color(0xFF0B141B) : Colors.white)
              : (isDark
                    ? AppDarkColors.whatsappGreen
                    : const Color(0xFF15803D));
          borderColor = isSelected ? AppColors.whatsappGreen : unselectedBorder;
        } else if (normalized == 'scheduled') {
          bgColor = isSelected ? const Color(0xFFD97706) : unselectedBg;
          textColor = isSelected
              ? Colors.white
              : (isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309));
          borderColor = isSelected ? const Color(0xFFD97706) : unselectedBorder;
        } else {
          // Cancelled
          bgColor = isSelected ? const Color(0xFFEF4444) : unselectedBg;
          textColor = isSelected ? Colors.white : const Color(0xFFEF4444);
          borderColor = isSelected ? const Color(0xFFEF4444) : unselectedBorder;
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () => onStatusSelected(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 1.0 : 1.0,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
