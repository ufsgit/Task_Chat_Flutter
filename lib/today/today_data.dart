import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Separated hardcoded data for Today / TaskChat page.
/// Modifying or replacing this list will update the data without touching any UI code.
final List<Map<String, dynamic>> todayChatItems = [
  {
    'id': '1',
    'title': 'Arun',
    'avatarLetter': 'H',
    'avatarBgColor': AppColors.cancelledBg,
    'avatarTextColor': AppColors.cancelledText,
    'avatarBorderColor': null,
    'hasVerifiedBadge': false,
    'indicatorColor': Colors.transparent,
    'tagText': 'Cancelled',
    'tagBgColor': AppColors.cancelledBg,
    'tagTextColor': AppColors.cancelledText,
    'location': 'Kakkanad',
    'date': '26/02/2026',
    'unreadCount': 0,
    'isPending': true,
  },
  {
    'id': '2',
    'title': 'Devika',
    'avatarLetter': 'H',
    'avatarBgColor': AppColors.completedBg,
    'avatarTextColor': AppColors.completedText,
    'avatarBorderColor': null,
    'hasVerifiedBadge': false,
    'indicatorColor': Colors.transparent,
    'tagText': 'Completed',
    'tagBgColor': AppColors.completedBg,
    'tagTextColor': AppColors.completedText,
    'location': 'Thrissur',
    'date': '30/01/2026',
    'unreadCount': 0,
    'isPending': true,
  },
  {
    'id': '3',
    'title': 'Abhijith',
    'avatarLetter': 'G',
    'avatarBgColor': AppColors.newAvatarBg,
    'avatarTextColor': AppColors.newAvatarText,
    'avatarBorderColor': null,
    'hasVerifiedBadge': false,
    'indicatorColor': const Color(0xFFEF4444), // Red indicator bar for 'New'
    'tagText': 'New',
    'tagBgColor': AppColors.newBg,
    'tagTextColor': AppColors.newText,
    'location': 'Kochi',
    'date': '01/01/2026',
    'unreadCount': 1,
    'isPending': true,
  },
  {
    'id': '4',
    'title': 'Syam',
    'avatarLetter': 'B',
    'avatarBgColor': AppColors.purpleAvatarBg,
    'avatarTextColor': AppColors.purpleAvatarText,
    'avatarBorderColor': null,
    'hasVerifiedBadge': false,
    'indicatorColor': Colors.transparent,
    'tagText': 'In-progress',
    'tagBgColor': AppColors.inProgressBg,
    'tagTextColor': AppColors.inProgressText,
    'location': 'Allepy',
    'date': '02/08/2026',
    'unreadCount': 0,
    'isPending': true,
  },
  {
    'id': '5',
    'title': 'Ram',
    'avatarLetter': 'W',
    'avatarBgColor': AppColors.completedBg,
    'avatarTextColor': AppColors.completedText,
    'avatarBorderColor': null,
    'hasVerifiedBadge': true,
    'indicatorColor': Colors.transparent,
    'tagText': 'Completed',
    'tagBgColor': AppColors.completedBg,
    'tagTextColor': AppColors.completedText,
    'location': 'Kollam',
    'date': '20/10/2026',
    'unreadCount': 0,
    'isPending': true,
  },
];

/// Updates the status and appearance of a chat item by customer title/name.
void updateChatItemStatus({
  required String customerName,
  required String newStatus,
  String? newLocation,
}) {
  final index = todayChatItems.indexWhere(
    (item) =>
        (item['title'] as String?)?.toLowerCase().trim() ==
        customerName.toLowerCase().trim(),
  );

  if (index != -1) {
    final item = todayChatItems[index];
    item['tagText'] = newStatus;

    if (newLocation != null && newLocation.isNotEmpty) {
      item['location'] = newLocation;
    }

    switch (newStatus.toLowerCase()) {
      case 'completed':
        item['tagBgColor'] = AppColors.completedBg;
        item['tagTextColor'] = AppColors.completedText;
        item['indicatorColor'] = Colors.transparent;
        item['isPending'] = false;
        break;
      case 'new':
        item['tagBgColor'] = AppColors.newBg;
        item['tagTextColor'] = AppColors.newText;
        item['indicatorColor'] = const Color(0xFFEF4444);
        item['isPending'] = true;
        break;
      case 'scheduled':
        item['tagBgColor'] = const Color(0xFFFEF3C7);
        item['tagTextColor'] = const Color(0xFFD97706);
        item['indicatorColor'] = Colors.transparent;
        item['isPending'] = true;
        break;
      case 'cancelled':
        item['tagBgColor'] = AppColors.cancelledBg;
        item['tagTextColor'] = AppColors.cancelledText;
        item['indicatorColor'] = Colors.transparent;
        item['isPending'] = false;
        break;
    }
  }
}
