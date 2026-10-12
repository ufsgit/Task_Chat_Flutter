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

    return Row(
      children: statusList.map((status) {
        final isSelected =
            selectedStatus.toLowerCase() == status.toLowerCase();

        Color bgColor;
        Color textColor;

        if (status == 'Completed') {
          bgColor = isSelected
              ? AppColors.whatsappGreen
              : (options != null ? const Color(0xFFEFF6FF) : const Color(0xFFDCFCE7));
          textColor = isSelected
              ? Colors.white
              : (options != null ? const Color(0xFF334155) : const Color(0xFF15803D));
        } else if (status == 'Scheduled') {
          bgColor = isSelected ? const Color(0xFFD97706) : const Color(0xFFEFF6FF);
          textColor = isSelected ? Colors.white : const Color(0xFF334155);
        } else {
          // Cancelled
          bgColor = isSelected
              ? const Color(0xFFEF4444)
              : (options != null ? const Color(0xFFEFF6FF) : const Color(0xFFFEF2F2));
          textColor = isSelected ? Colors.white : const Color(0xFFEF4444);
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
