import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Lead Stage',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(stages.length, (index) {
            final isSelected = selectedIndex == index;
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
                        ? const Color(0xFF34D399)
                        : const Color(0xFFEDF4FB),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    stages[index],
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF064E3B)
                          : const Color(0xFF475569),
                      fontSize: 13.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
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
