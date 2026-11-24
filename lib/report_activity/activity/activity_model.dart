import 'package:flutter/material.dart';
import '../../core/status_color_service.dart';

/// Helper to parse hex colors like "#3b82f6" or "3b82f6" safely.
Color? parseHexColor(String? hexString) =>
    StatusColorService.parseHexColor(hexString);

/// Resolves user-friendly role name based on action_by_role_id.
/// role 3 -> Branch Manager, role 2 -> Coordinator, role 1 -> Company, etc.
String getRoleNameFromId(dynamic roleId) {
  final id = int.tryParse(roleId?.toString() ?? '');
  switch (id) {
    case 1:
      return 'Company';
    case 2:
      return 'Coordinator';
    case 3:
      return 'Branch Manager';
    case 4:
      return 'Dealer';
    case 5:
      return 'Customer';
    default:
      return '';
  }
}

/// Data model representing an activity history item fetched from /api/booking-history.
class ActivityModel {
  final String id;
  final String title;
  final String avatarLetter;
  final Color avatarBgColor;
  final Color avatarTextColor;
  final String date;
  final DateTime? dateTime;
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
  final String? location;
  final String? mobile;
  final int? bookingId;
  final List<String> documents;
  final String? clientName;
  final String? status;
  final String? notes;
  final String? createdByName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? actionType;
  final int? actionByRoleId;
  final String? actionByName;

  const ActivityModel({
    required this.id,
    required this.title,
    required this.avatarLetter,
    required this.avatarBgColor,
    required this.avatarTextColor,
    required this.date,
    this.dateTime,
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
    this.location,
    this.mobile,
    this.bookingId,
    this.documents = const [],
    this.clientName,
    this.status,
    this.notes,
    this.createdByName,
    this.createdAt,
    this.updatedAt,
    this.actionType,
    this.actionByRoleId,
    this.actionByName,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    final id = json['history_id']?.toString() ??
        json['id']?.toString() ??
        json['_id']?.toString() ??
        json['booking_id']?.toString() ??
        json['bookingId']?.toString() ??
        '';

    // 1. Name: use booking_name as name, with fallback to clientName / customerName
    final name = json['booking_name']?.toString() ??
        json['clientName']?.toString() ??
        json['customerName']?.toString() ??
        json['name']?.toString() ??
        json['title']?.toString() ??
        json['client_name']?.toString() ??
        'Client';

    // 2. Status & Action Type: use action_type for latest status display on activity page
    final actionTypeRaw = json['action_type']?.toString().trim() ??
        json['actionType']?.toString().trim();
    final hasActionType = actionTypeRaw != null && actionTypeRaw.isNotEmpty;

    final fallbackStatus = json['new_status_label']?.toString().trim() ??
        json['new_status_code']?.toString().trim() ??
        json['statusLabel']?.toString().trim() ??
        json['statusCode']?.toString().trim() ??
        json['status']?.toString().trim() ??
        'New';

    final underlyingStatus = fallbackStatus.isNotEmpty
        ? '${fallbackStatus[0].toUpperCase()}${fallbackStatus.substring(1).toLowerCase()}'
        : 'New';

    final displayStatus = hasActionType ? actionTypeRaw : underlyingStatus;

    // 3. Notes: customer_note or staff_note or notes or action_type
    final note = json['customer_note']?.toString() ??
        json['staff_note']?.toString() ??
        json['notes']?.toString() ??
        json['note']?.toString() ??
        json['remarks']?.toString() ??
        json['action_type']?.toString();

    // 4. Role & Author: action_by_role_id (3 -> Branch Manager, 2 -> Coordinator) and action_by_name
    final actionByRoleId = json['action_by_role_id'] is int
        ? json['action_by_role_id'] as int
        : int.tryParse(json['action_by_role_id']?.toString() ?? '');

    final actionByName = json['action_by_name']?.toString() ??
        json['createdByName']?.toString() ??
        json['created_by_name']?.toString() ??
        json['loginName']?.toString() ??
        json['to_branch_head_name']?.toString() ??
        '';

    final roleName = getRoleNameFromId(actionByRoleId);

    String? subtitlePrefix;
    String? subtitleHighlight;
    if (actionByName.isNotEmpty) {
      if (roleName.isNotEmpty) {
        subtitlePrefix = '$roleName: ';
        subtitleHighlight = actionByName;
      } else {
        subtitlePrefix = 'Updated by ';
        subtitleHighlight = actionByName;
      }
    }

    // 5. Date parsing
    DateTime? dt;
    final rawDate = json['created_at'] ??
        json['createdAt'] ??
        json['new_schedule_date'] ??
        json['scheduleDate'] ??
        json['scheduledDate'] ??
        json['schedule_date'] ??
        json['date'] ??
        json['timestamp'];

    if (rawDate != null) {
      if (rawDate is DateTime) {
        dt = rawDate;
      } else {
        dt = DateTime.tryParse(rawDate.toString());
      }
    }

    String formattedDate = '';
    if (dt != null) {
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      formattedDate = '$day/$month/${dt.year}';
    } else if (rawDate != null) {
      formattedDate = rawDate.toString();
    }

    // Determine timeFilter: Today, This Week, This Month, Older
    String timeFilter = 'Today';
    if (dt != null) {
      final now = DateTime.now();
      final diff = now.difference(dt);
      final isSameDay =
          now.year == dt.year && now.month == dt.month && now.day == dt.day;
      if (isSameDay) {
        timeFilter = 'Today';
      } else if (diff.inDays <= 7 && diff.inDays >= 0) {
        timeFilter = 'This Week';
      } else if (diff.inDays <= 30 && diff.inDays >= 0) {
        timeFilter = 'This Month';
      } else {
        timeFilter = 'Older';
      }
    }

    // 6. Colors: use new_status_color_code if available
    final customColor = parseHexColor(
      json['new_status_color_code']?.toString() ??
          json['old_status_color_code']?.toString() ??
          json['statusColorCode']?.toString(),
    );

    final statusLower = displayStatus.toLowerCase();
    final underlyingLower = underlyingStatus.toLowerCase();
    final isDeleted =
        statusLower.contains('delet') || underlyingLower.contains('delet');

    final resolvedColor = isDeleted
        ? const Color(0xFFEF4444)
        : (customColor ??
            (StatusColorService.getColor(underlyingStatus) !=
                    const Color(0xFF3B82F6)
                ? StatusColorService.getColor(underlyingStatus)
                : StatusColorService.getColor(displayStatus)));
    final avatarBg = resolvedColor.withValues(alpha: 0.15);
    final avatarFg = resolvedColor;
    final tagBg = resolvedColor.withValues(alpha: 0.12);
    final tagFg = resolvedColor;
    IconData? tagIcon;
    bool isPending = false;

    if (isDeleted) {
      tagIcon = Icons.delete_outline_rounded;
      isPending = false;
    } else if (underlyingLower.contains('complete') ||
        statusLower.contains('complete') ||
        statusLower.contains('done')) {
      tagIcon = Icons.check_circle_rounded;
      isPending = false;
    } else if (underlyingLower.contains('cancel') ||
        statusLower.contains('cancel')) {
      tagIcon = Icons.cancel_rounded;
      isPending = false;
    } else if (underlyingLower.contains('schedul') ||
        statusLower.contains('schedul')) {
      tagIcon = Icons.calendar_today_rounded;
      isPending = true;
    } else if (statusLower.contains('transfer')) {
      tagIcon = Icons.swap_horiz_rounded;
      isPending = false;
    } else if (statusLower.contains('note')) {
      tagIcon = Icons.notes_rounded;
      isPending = false;
    } else if (statusLower.contains('update') || statusLower.contains('edit')) {
      tagIcon = Icons.update_rounded;
      isPending = false;
    } else {
      tagIcon = Icons.fiber_new_rounded;
      isPending = true;
    }

    final rawDocs = json['documents'];
    final docs = rawDocs is List
        ? rawDocs.map((e) => e.toString()).toList()
        : <String>[];

    final district = json['to_assigned_head_district_name']?.toString() ??
        json['from_assigned_head_district_name']?.toString() ??
        json['districtName']?.toString() ??
        json['district']?.toString();

    final location = district != null && district.trim().isNotEmpty
        ? district.trim()
        : (json['to_branch_head_name']?.toString() ??
            json['areaName']?.toString() ??
            json['address']?.toString() ??
            '');

    final trimmedName = name.trim();
    final letter = trimmedName.isNotEmpty ? trimmedName[0].toUpperCase() : 'B';

    final bId = json['booking_id'] is int
        ? json['booking_id'] as int
        : int.tryParse(json['booking_id']?.toString() ?? '') ??
            (json['bookingId'] is int
                ? json['bookingId'] as int
                : int.tryParse(json['bookingId']?.toString() ?? ''));

    return ActivityModel(
      id: id,
      title: name,
      avatarLetter: letter,
      avatarBgColor: avatarBg,
      avatarTextColor: avatarFg,
      date: formattedDate.isNotEmpty ? formattedDate : 'Today',
      dateTime: dt,
      subtitlePrefix: subtitlePrefix,
      subtitleHighlight: subtitleHighlight,
      statusTag: displayStatus,
      statusTagIcon: tagIcon,
      statusTagBg: tagBg,
      statusTagTextColor: tagFg,
      noteText: note != null && note.trim().isNotEmpty ? note.trim() : null,
      noteIcon: Icons.notes_rounded,
      noteIconColor: tagFg,
      timeFilter: timeFilter,
      isPending: isPending,
      unreadCount: 0,
      location: location,
      mobile: json['mobile']?.toString() ?? json['contactPhone']?.toString(),
      bookingId: bId,
      documents: docs,
      clientName: name,
      status: underlyingStatus,
      notes: note,
      createdByName: actionByName,
      createdAt: dt,
      actionType: actionTypeRaw,
      actionByRoleId: actionByRoleId,
      actionByName: actionByName,
    );
  }
}

/// Backwards compatibility alias for widgets expecting `ActivityItemData`.
typedef ActivityItemData = ActivityModel;

/// Available time filter tabs for activity history.
const List<String> activityTimeFilters = [
  'All',
  'Today',
  'This Week',
  'This Month',
];
