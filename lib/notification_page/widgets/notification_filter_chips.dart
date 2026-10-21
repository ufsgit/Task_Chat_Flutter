import 'package:flutter/material.dart';
import '../../core/widgets/app_filter_chip.dart';
import '../notification_data.dart';

/// Filter chip selector for "All" and "Pending" notifications using universal AppFilterChip.
class NotificationFilterChips extends StatelessWidget {
  final NotificationFilter selectedFilter;
  final ValueChanged<NotificationFilter> onFilterChanged;

  const NotificationFilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          AppFilterChip(
            label: 'All',
            isSelected: selectedFilter == NotificationFilter.all,
            onTap: () => onFilterChanged(NotificationFilter.all),
          ),
          const SizedBox(width: 8),
          AppFilterChip(
            label: 'Pending',
            isSelected: selectedFilter == NotificationFilter.pending,
            onTap: () => onFilterChanged(NotificationFilter.pending),
          ),
        ],
      ),
    );
  }
}
