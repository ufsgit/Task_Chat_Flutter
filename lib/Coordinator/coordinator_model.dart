import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../today/today_view_model.dart';
import '../update_status/coordinators/coordinator_update_status_logic.dart';

/// Available quick tab filters for Coordinator.
const List<String> coordinatorQuickFilters = ['All', 'Unread', 'Pending'];

/// Available status filter options for Coordinator bottom sheet filter.
const List<String> coordinatorStatusOptions = [
  'All',
  'New',
  'Scheduled',
  'Completed',
  'Cancelled',
];

/// Data model representing a Coordinator task item.
class CoordinatorItem {
  final String id;
  final String title;
  final String location;
  final String tagText;
  final String date;
  final int unreadCount;
  final bool hasVerifiedBadge;
  final String avatarLetter;
  final Color avatarBgColor;
  final Color avatarTextColor;
  final Color? avatarBorderColor;
  final Color tagBgColor;
  final Color tagTextColor;
  final String branchManager;
  final String role;
  final bool isPending;

  const CoordinatorItem({
    required this.id,
    required this.title,
    required this.location,
    required this.tagText,
    required this.date,
    this.unreadCount = 0,
    this.hasVerifiedBadge = false,
    required this.avatarLetter,
    required this.avatarBgColor,
    required this.avatarTextColor,
    this.avatarBorderColor,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.branchManager,
    this.role = 'Branch Manager',
    this.isPending = true,
  });

  factory CoordinatorItem.fromMap(Map<String, dynamic> map) {
    return CoordinatorItem(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      tagText: map['tagText']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      unreadCount: (map['unreadCount'] as int?) ?? 0,
      hasVerifiedBadge: (map['hasVerifiedBadge'] as bool?) ?? false,
      avatarLetter: map['avatarLetter']?.toString() ?? '',
      avatarBgColor: (map['avatarBgColor'] as Color?) ?? AppColors.surfaceGrey,
      avatarTextColor:
          (map['avatarTextColor'] as Color?) ?? AppColors.textSecondary,
      avatarBorderColor: map['avatarBorderColor'] as Color?,
      tagBgColor: (map['tagBgColor'] as Color?) ?? AppColors.completedBg,
      tagTextColor: (map['tagTextColor'] as Color?) ?? AppColors.completedText,
      branchManager:
          map['branchManager']?.toString() ?? map['role']?.toString() ?? 'Branch Manager',
      role: map['role']?.toString() ?? 'Branch Manager',
      isPending: (map['isPending'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'location': location,
        'tagText': tagText,
        'date': date,
        'unreadCount': unreadCount,
        'hasVerifiedBadge': hasVerifiedBadge,
        'avatarLetter': avatarLetter,
        'avatarBgColor': avatarBgColor,
        'avatarTextColor': avatarTextColor,
        'avatarBorderColor': avatarBorderColor,
        'tagBgColor': tagBgColor,
        'tagTextColor': tagTextColor,
        'branchManager': branchManager,
        'role': role,
        'isPending': isPending,
      };
}

int _lastTodayLength = -1;
int _lastTodayVersion = -1;
List<Map<String, dynamic>> _cachedCoordinatorChatItems = [];

/// Invalidate cached coordinator chat items explicitly.
void invalidateCoordinatorCache() {
  _lastTodayVersion = -1;
  _lastTodayLength = -1;
  _cachedCoordinatorChatItems = [];
}

/// Separated data source for Coordinator (formerly Super Admin).
/// Wraps centralized chat items with the extra role badge field ('Branch Manager')
/// and assigned branch manager names.
List<Map<String, dynamic>> get coordinatorChatItems {
  final currentVersion = todayChatItemsVersion;
  if (todayChatItems.isEmpty) {
    _lastTodayLength = 0;
    _lastTodayVersion = currentVersion;
    _cachedCoordinatorChatItems = [];
    return _cachedCoordinatorChatItems;
  }
  if (_cachedCoordinatorChatItems.isNotEmpty &&
      _lastTodayLength == todayChatItems.length &&
      _lastTodayVersion == currentVersion) {
    return _cachedCoordinatorChatItems;
  }
  final managers = availableBranchManagers;
  _lastTodayLength = todayChatItems.length;
  _lastTodayVersion = currentVersion;
  _cachedCoordinatorChatItems = todayChatItems.asMap().entries.map((entry) {
    final index = entry.key;
    final item = entry.value;
    final assignedManager = managers[index % managers.length];
    return {
      ...item,
      'role': 'Branch Manager',
      'branchManager': assignedManager,
    };
  }).toList();
  return _cachedCoordinatorChatItems;
}

/// Backward compatibility alias for coordinatorChatItems.
List<Map<String, dynamic>> get superAdminChatItems => coordinatorChatItems;
