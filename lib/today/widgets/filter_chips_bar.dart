import 'package:flutter/material.dart';
import '../../core/widgets/app_filter_chip.dart';

/// Reusable horizontal filter chips selector bar.
class FilterChipsBar extends StatelessWidget {
  final List<String> filters;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const FilterChipsBar({
    super.key,
    required this.filters,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: filters.asMap().entries.map((entry) {
              final index = entry.key;
              final filter = entry.value;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: AppFilterChip(
                  label: filter,
                  isSelected: selectedIndex == index,
                  onTap: () => onSelected(index),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
