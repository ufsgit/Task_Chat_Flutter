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
  final bool isPending;
  final int unreadCount;

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
    this.isPending = false,
    this.unreadCount = 0,
  });
}

/// Filter options for Activity screen.
const List<String> activityTimeFilters = ['Today', 'This Week', 'This Month'];

/// Mock activity items matching the reference design.
const List<ActivityItemData> defaultActivityItems = [
  ActivityItemData(
    id: '1',
    title: 'Arun',
    avatarLetter: 'A',
    avatarBgColor: Color(0xFFFFEBEB),
    avatarTextColor: Color(0xFFE53935),
    date: '12/06/2026',
    statusTag: 'Cancelled',
    statusTagBg: Color(0xFFFFEBEB),
    statusTagTextColor: Color(0xFFE53935),
    noteText: 'Rescheduled to monday',
    noteIcon: Icons.favorite_border_rounded,
    noteIconColor: Color(0xFFE53935),
    timeFilter: 'Today',
    isPending: true,
    unreadCount: 0,
  ),
  ActivityItemData(
    id: '2',
    title: 'Devika',
    avatarLetter: 'D',
    avatarBgColor: Color(0xFF4ADE80),
    avatarTextColor: Color(0xFF065F46),
    date: '01/08/2026',
    statusTag: 'Completed',
    statusTagIcon: Icons.check_circle_rounded,
    statusTagBg: Color(0xFFDCFCE7),
    statusTagTextColor: Color(0xFF15803D),
    timeFilter: 'Today',
    isPending: false,
    unreadCount: 0,
  ),
  ActivityItemData(
    id: '3',
    title: 'Abhijith',
    avatarLetter: 'A',
    avatarBgColor: Color(0xFFE0F2FE),
    avatarTextColor: Color(0xFF0284C7),
    date: '05/08/2026',
    statusTag: 'New',
    statusTagBg: Color(0xFFDBEAFE),
    statusTagTextColor: Color(0xFF2563EB),
    noteText: 'Requested brochure and price list',
    noteIcon: Icons.chat_bubble_outline_rounded,
    noteIconColor: Color(0xFF2563EB),
    timeFilter: 'Today',
    isPending: true,
    unreadCount: 2,
  ),
  ActivityItemData(
    id: '4',
    title: 'Syam',
    avatarLetter: 'S',
    avatarBgColor: Color(0xFFF3E8FF),
    avatarTextColor: Color(0xFF7E22CE),
    date: '10/08/2026',
    statusTag: 'Scheduled',
    statusTagIcon: Icons.schedule_rounded,
    statusTagBg: Color(0xFFE0F2FE),
    statusTagTextColor: Color(0xFF0284C7),
    noteText: 'Site visit scheduled for 3:00 PM',
    noteIcon: Icons.access_time_rounded,
    noteIconColor: Color(0xFF7E22CE),
    timeFilter: 'This Week',
    isPending: true,
    unreadCount: 0,
  ),
  ActivityItemData(
    id: '5',
    title: 'Ravi',
    avatarLetter: 'R',
    avatarBgColor: Color(0xFFE0F2FE),
    avatarTextColor: Color(0xFF0F766E),
    date: '12/08/2026',
    subtitlePrefix: 'Rescheduled by ',
    subtitleHighlight: 'Sita Sharma',
    statusTag: 'Scheduled',
    statusTagIcon: Icons.schedule_rounded,
    statusTagBg: Color(0xFFE0F2FE),
    statusTagTextColor: Color(0xFF0284C7),
    noteText: 'Tomorrow, 10:00 AM (Technician confirmed)',
    noteIcon: Icons.access_time_rounded,
    noteIconColor: Color(0xFF334155),
    timeFilter: 'This Month',
    isPending: true,
    unreadCount: 1,
  ),
];
