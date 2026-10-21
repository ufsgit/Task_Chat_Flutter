import 'package:flutter/material.dart';

/// Filter selection for notifications
enum NotificationFilter { all, pending }

/// Data model representing a single notification entry.
class NotificationItem {
  final String id;
  final String name;
  final String avatarInitial;
  final Color avatarBgColor;
  final Color avatarTextColor;
  final String tag;
  final Color tagBgColor;
  final Color tagTextColor;
  final String location;
  final String timestamp;
  final bool isTimestampBold;
  final bool hasRedIndicator;
  final bool isPending;
  final String? phone;
  final String? email;

  const NotificationItem({
    required this.id,
    required this.name,
    required this.avatarInitial,
    required this.avatarBgColor,
    required this.avatarTextColor,
    this.tag = 'New',
    this.tagBgColor = const Color(0xFFDBEAFE),
    this.tagTextColor = const Color(0xFF2563EB),
    required this.location,
    required this.timestamp,
    this.isTimestampBold = false,
    this.hasRedIndicator = false,
    this.isPending = false,
    this.phone,
    this.email,
  });

  NotificationItem copyWith({
    String? id,
    String? name,
    String? avatarInitial,
    Color? avatarBgColor,
    Color? avatarTextColor,
    String? tag,
    Color? tagBgColor,
    Color? tagTextColor,
    String? location,
    String? timestamp,
    bool? isTimestampBold,
    bool? hasRedIndicator,
    bool? isPending,
    String? phone,
    String? email,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarInitial: avatarInitial ?? this.avatarInitial,
      avatarBgColor: avatarBgColor ?? this.avatarBgColor,
      avatarTextColor: avatarTextColor ?? this.avatarTextColor,
      tag: tag ?? this.tag,
      tagBgColor: tagBgColor ?? this.tagBgColor,
      tagTextColor: tagTextColor ?? this.tagTextColor,
      location: location ?? this.location,
      timestamp: timestamp ?? this.timestamp,
      isTimestampBold: isTimestampBold ?? this.isTimestampBold,
      hasRedIndicator: hasRedIndicator ?? this.hasRedIndicator,
      isPending: isPending ?? this.isPending,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}

/// Represents a grouped section of notifications (e.g., TODAY, THIS WEEK, EARLIER).
class NotificationSection {
  final String title;
  final List<NotificationItem> items;

  const NotificationSection({
    required this.title,
    required this.items,
  });
}

/// Default dataset matching the provided design.
const List<NotificationSection> defaultNotificationSections = [
  NotificationSection(
    title: 'TODAY',
    items: [
      NotificationItem(
        id: 'notif_1',
        name: 'Ramesh Kumar',
        avatarInitial: 'A',
        avatarBgColor: Color(0xFFDBEAFE),
        avatarTextColor: Color(0xFF2563EB),
        tag: 'New',
        location: 'kochi',
        timestamp: '10m ago',
        hasRedIndicator: false,
        isPending: false,
        phone: '+91 98765 43210',
      ),
      NotificationItem(
        id: 'notif_2',
        name: 'Manoj jayan',
        avatarInitial: 'D',
        avatarBgColor: Color(0xFFF3E8FF),
        avatarTextColor: Color(0xFF9333EA),
        tag: 'New',
        location: 'kaloor',
        timestamp: '1h ago',
        hasRedIndicator: false,
        isPending: false,
        phone: '+91 98471 23456',
      ),
      NotificationItem(
        id: 'notif_3',
        name: 'Sunita devi',
        avatarInitial: 'A',
        avatarBgColor: Color(0xFFCCFBF1),
        avatarTextColor: Color(0xFF0F766E),
        tag: 'New',
        location: 'kollam',
        timestamp: '3h ago',
        hasRedIndicator: true,
        isPending: true,
        phone: '+91 94470 11223',
      ),
    ],
  ),
  NotificationSection(
    title: 'THIS WEEK',
    items: [
      NotificationItem(
        id: 'notif_4',
        name: 'Sita Sharma',
        avatarInitial: 'S',
        avatarBgColor: Color(0xFFFEF3C7),
        avatarTextColor: Color(0xFFD97706),
        tag: 'New',
        location: 'Neyyatinkara',
        timestamp: '2d ago',
        hasRedIndicator: false,
        isPending: false,
        phone: '+91 97451 98765',
      ),
      NotificationItem(
        id: 'notif_5',
        name: 'Michael Jenkins',
        avatarInitial: 'R',
        avatarBgColor: Color(0xFFDCFCE7),
        avatarTextColor: Color(0xFF16A34A),
        tag: 'New',
        location: 'Vytilla',
        timestamp: '4d ago',
        hasRedIndicator: false,
        isPending: false,
        phone: '+91 94951 88776',
      ),
      NotificationItem(
        id: 'notif_6',
        name: 'Sneha Suresh',
        avatarInitial: 'SS',
        avatarBgColor: Color(0xFFFFE4E6),
        avatarTextColor: Color(0xFFE11D48),
        tag: 'New',
        location: 'Neyyatinkara',
        timestamp: '4d ago',
        isTimestampBold: false,
        hasRedIndicator: false,
        isPending: true,
        phone: '+91 98462 33445',
      ),
    ],
  ),
  NotificationSection(
    title: 'EARLIER',
    items: [
      NotificationItem(
        id: 'notif_7',
        name: 'Malavika Sharma',
        avatarInitial: 'PC',
        avatarBgColor: Color(0xFFFFE4E6),
        avatarTextColor: Color(0xFFE11D48),
        tag: 'New',
        location: 'Kottayam',
        timestamp: '1w ago',
        hasRedIndicator: false,
        isPending: false,
        phone: '+91 98460 77889',
      ),
      NotificationItem(
        id: 'notif_8',
        name: 'Tino thomas',
        avatarInitial: 'TT',
        avatarBgColor: Color(0xFFCCFBF1),
        avatarTextColor: Color(0xFF0F766E),
        tag: 'New',
        location: 'kottayam',
        timestamp: '2w ago',
        hasRedIndicator: false,
        isPending: true,
        phone: '+91 94461 44556',
      ),
    ],
  ),
];

/// Helper method to filter sections based on active filter.
List<NotificationSection> filterNotificationSections(
  List<NotificationSection> sections,
  NotificationFilter filter,
) {
  if (filter == NotificationFilter.all) {
    return sections;
  }

  // Filter only pending items
  return sections
      .map((section) {
        final filteredItems =
            section.items.where((item) => item.isPending).toList();
        return NotificationSection(
          title: section.title,
          items: filteredItems,
        );
      })
      .where((section) => section.items.isNotEmpty)
      .toList();
}
