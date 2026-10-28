import 'package:flutter/material.dart';
import '../../core/widgets/app_filter_chip.dart';

/// Reusable horizontal time filter selector for Dashboard using universal AppFilterChip.
/// Supports preset periods as well as interactive Custom date range selection.
class DashboardTimeFilterBar extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onFilterSelected;
  final VoidCallback? onCustomTap;

  const DashboardTimeFilterBar({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
    this.onCustomTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        child: Row(
          children: filters.map((filter) {
            final isSelected = filter == selectedFilter;
            final isCustom = filter.startsWith('Custom') || filter == 'Custom';
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: AppFilterChip(
                label: filter,
                isSelected: isSelected,
                icon: isCustom ? Icons.calendar_today_rounded : null,
                onTap: () {
                  if (isCustom && onCustomTap != null) {
                    onCustomTap!();
                  } else {
                    onFilterSelected(filter);
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
