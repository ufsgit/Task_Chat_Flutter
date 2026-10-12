import 'package:flutter/material.dart';

/// Data model representing an activity history item.
class ActivityItemData {
  final String id;
  final String title;
  final String avatarLetter;
  final Color avatarBgColor;
  final Color avatarTextColor;
  final String date;
  final String? subtitlePrefix;
  final String? subtitleHighlight;
  final String? statusTag;
  final IconData? statusTagIcon;
  final Color? statusTagBg;
  final Color? statusTagTextColor;
  final String? noteText;
  final IconData? noteIcon;
  final Color? noteIconColor;
  final String timeFilter;

  const ActivityItemData({
    required this.id,
    required this.title,
    required this.avatarLetter,
    required this.avatarBgColor,
    required this.avatarTextColor,
    required this.date,
    this.subtitlePrefix,
    this.subtitleHighlight,
    this.statusTag,
    this.statusTagIcon,
    this.statusTagBg,
    this.statusTagTextColor,
    this.noteText,
    this.noteIcon,
    this.noteIconColor,
    this.timeFilter = 'Today',
  });
}

/// Filter options for Activity screen.
const List<String> activityTimeFilters = [
  'Today',
  'This Week',
  'This Month',
];

/// Mock activity items matching the reference design.
const List<ActivityItemData> defaultActivityItems = [
  ActivityItemData(
    id: '1',
    title: 'Arun',
    avatarLetter: 'A',
    avatarBgColor: Color(0xFFE0F2FE),
    avatarTextColor: Color(0xFF0F766E),
    date: '12/06/2026',
    noteText: 'Rescheduled to monday',
    noteIcon: Icons.favorite_border_rounded,
    noteIconColor: Color(0xFF0F766E),
    timeFilter: 'Today',
  ),
  ActivityItemData(
    id: '2',
    title: 'Devika',
    avatarLetter: 'F',
    avatarBgColor: Color(0xFF4ADE80),
    avatarTextColor: Color(0xFF065F46),
    date: '01/08/2026',
    statusTag: 'Completed',
    statusTagIcon: Icons.check_circle_rounded,
    statusTagBg: Color(0xFFDCFCE7),
    statusTagTextColor: Color(0xFF15803D),
    timeFilter: 'Today',
  ),
  ActivityItemData(
    id: '3',
    title: 'Ravi',
    avatarLetter: 'H',
    avatarBgColor: Color(0xFFE0F2FE),
    avatarTextColor: Color(0xFF0F766E),
    date: '12/08/2026',
    subtitlePrefix: 'Rescheduled by ',
    subtitleHighlight: 'Sita Sharma',
    noteText: 'Tomorrow, 10:00 AM (Technician confirmed)',
    noteIcon: Icons.access_time_rounded,
    noteIconColor: Color(0xFF334155),
    timeFilter: 'Today',
  ),
];
