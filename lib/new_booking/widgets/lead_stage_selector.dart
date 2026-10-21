import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Reusable horizontal selector for lead pipeline stages.
class LeadStageSelector extends StatelessWidget {
  final List<String> stages;
  final int selectedIndex;
  final ValueChanged<int> onStageSelected;

  const LeadStageSelector({
    super.key,
    required this.stages,
    required this.selectedIndex,
    required this.onStageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppDarkColors.textPrimary : const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(stages.length, (index) {
            final isSelected = selectedIndex == index;
            final unselectedBg = isDark
                ? AppDarkColors.surfaceCard
                : const Color(0xFFEDF4FB);
            final unselectedText = isDark
                ? AppDarkColors.textSubtitle
                : const Color(0xFF475569);

            return Padding(
              padding: const EdgeInsets.only(right: 10.0),
              child: GestureDetector(
                onTap: () => onStageSelected(index),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.whatsappGreen
                        : unselectedBg,
                    borderRadius: BorderRadius.circular(20),
                    border: isDark && !isSelected
                        ? Border.all(color: AppDarkColors.border, width: 1)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    stages[index],
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : unselectedText,
                      fontSize: 13.5,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
