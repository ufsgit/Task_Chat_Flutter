import 'package:flutter/material.dart';
import '../../core/widgets/app_filter_chip.dart';

/// Reusable filter chips bar for the Activity screen using universal AppFilterChip.
class ActivityFilterChipsBar extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final ValueChanged<String> onSelected;

  const ActivityFilterChipsBar({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onSelected,
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

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: AppFilterChip(
                label: filter,
                isSelected: isSelected,
                icon: isSelected ? Icons.check : null,
                onTap: () => onSelected(filter),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
