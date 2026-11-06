import 'package:flutter/material.dart';
import '../../core/status_color_service.dart';
import '../../core/theme.dart';
import '../models/status_chip_model.dart';
import 'status_chips_skeleton.dart';

/// Reusable status chip selector for backend-driven status options.
/// Uses the established color scheme (Green for Completed, Amber for Scheduled,
/// Red for Cancelled, Blue for New) with skeleton shimmer loading support.
class StatusSelectorChips extends StatelessWidget {
  final String selectedStatus;
  final ValueChanged<String> onStatusSelected;
  final List<StatusChipModel>? chips;
  final List<String>? options;
  final bool isLoading;

  const StatusSelectorChips({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
    this.chips,
    this.options,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const StatusChipsSkeleton(count: 3);
    }

    // Extract chip list either from StatusChipModel or string options
    final List<_ChipData> displayList = [];
    if (chips != null && chips!.isNotEmpty) {
      for (final chip in chips!) {
        displayList.add(_ChipData(
          label: chip.label,
          code: chip.code,
          colorHex: chip.colorCode,
        ));
      }
    } else if (options != null && options!.isNotEmpty) {
      for (final opt in options!) {
        displayList.add(_ChipData(label: opt, code: opt));
      }
    }

    if (displayList.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: displayList.map((item) {
        final isSelected =
            selectedStatus.toLowerCase().trim() == item.label.toLowerCase().trim() ||
            selectedStatus.toLowerCase().trim() == item.code.toLowerCase().trim();

        final unselectedBg = isDark ? AppDarkColors.surfaceCard : Colors.white;
        final unselectedBorder =
            isDark ? AppDarkColors.border : const Color(0xFFCBD5E1);

        Color bgColor = unselectedBg;
        Color textColor = isDark ? Colors.white70 : const Color(0xFF64748B);
        Color borderColor = unselectedBorder;

        final apiColor = StatusColorService.parseHexColor(item.colorHex) ??
            StatusColorService.getColor(item.label);

        bgColor = isSelected ? apiColor : unselectedBg;
        final isBright = apiColor.computeLuminance() > 0.65;
        textColor = isSelected
            ? (isBright ? const Color(0xFF0F172A) : Colors.white)
            : apiColor;
        borderColor = isSelected ? apiColor : unselectedBorder;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GestureDetector(
              onTap: () => onStatusSelected(item.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: borderColor,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  item.label,
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

class _ChipData {
  final String label;
  final String code;
  final String? colorHex;

  const _ChipData({
    required this.label,
    required this.code,
    this.colorHex,
  });
}
