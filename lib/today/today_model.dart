import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/widgets/user_circle_avatar.dart';

/// Formats any date string (ISO8601, MM/DD/YYYY, YYYY-MM-DD, etc.) into DD/MM/YYYY (date/month/year).
String formatDateToDayMonthYear(String? dateStr) {
  if (dateStr == null) return '';
  final trimmed = dateStr.trim();
  if (trimmed.isEmpty) return '';

  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) {
    final d = parsed.day.toString().padLeft(2, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final y = parsed.year.toString();
    return '$d/$m/$y';
  }

  if (trimmed.contains('/')) {
    final parts = trimmed.split('/');
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        if (parts[0].length == 4) {
          final d = p2.toString().padLeft(2, '0');
          final m = p1.toString().padLeft(2, '0');
          return '$d/$m/${parts[0]}';
        }
        if (parts[2].length == 4) {
          if (p0 > 12) {
            final d = p0.toString().padLeft(2, '0');
            final m = p1.toString().padLeft(2, '0');
            return '$d/$m/${parts[2]}';
          }
          final d = p1.toString().padLeft(2, '0');
          final m = p0.toString().padLeft(2, '0');
          return '$d/$m/${parts[2]}';
        }
      }
    }
  }

  if (trimmed.contains('-')) {
    final parts = trimmed.split('-');
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        if (parts[0].length == 4) {
          final d = p2.toString().padLeft(2, '0');
          final m = p1.toString().padLeft(2, '0');
          return '$d/$m/${parts[0]}';
        } else if (parts[2].length == 4) {
          if (p0 > 12) {
            final d = p0.toString().padLeft(2, '0');
            final m = p1.toString().padLeft(2, '0');
            return '$d/$m/${parts[2]}';
          }
          final d = p1.toString().padLeft(2, '0');
          final m = p0.toString().padLeft(2, '0');
          return '$d/$m/${parts[2]}';
        }
      }
    }
  }

  return trimmed;
}

/// Data model representing a booking lead from /api/booking.
class BookingModel {
  final int id;
  final String name;
  final String mobile;
  final String address;
  final String notes;
  final String status;
  final int? loginRoleId;
  final int? loginId;
  final String? loginName;
  final int? branchHeadId;
  final String? branchHeadName;
  final int? stateId;
  final String stateName;
  final int? districtId;
  final String districtName;
  final int? areaId;
  final String areaName;
  final List<String> documents;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? scheduleDate;

  BookingModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.notes,
    required this.status,
    this.loginRoleId,
    this.loginId,
    this.loginName,
    this.branchHeadId,
    this.branchHeadName,
    this.stateId,
    required this.stateName,
    this.districtId,
    required this.districtName,
    this.areaId,
    required this.areaName,
    required this.documents,
    this.createdAt,
    this.updatedAt,
    this.scheduleDate,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final rawDocs = json['documents'];
    final docs = rawDocs is List
        ? rawDocs.map((e) => e.toString()).toList()
        : <String>[];

    return BookingModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      status: json['status']?.toString() ?? 'NEW',
      loginRoleId: json['loginRoleId'] as int?,
      loginId: json['loginId'] as int?,
      loginName: json['loginName']?.toString(),
      branchHeadId: json['branchHeadId'] is int
          ? json['branchHeadId'] as int
          : int.tryParse(json['branchHeadId']?.toString() ?? '') ??
              (json['branch_head_id'] is int
                  ? json['branch_head_id'] as int
                  : int.tryParse(json['branch_head_id']?.toString() ?? '')),
      branchHeadName: json['branchHeadName']?.toString() ??
          json['branch_head_name']?.toString() ??
          json['loginName']?.toString(),
      stateId: json['stateId'] as int?,
      stateName: json['stateName']?.toString() ?? '',
      districtId: json['districtId'] as int?,
      districtName: json['districtName']?.toString() ?? '',
      areaId: json['areaId'] as int?,
      areaName: json['areaName']?.toString() ?? '',
      documents: docs,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      scheduleDate: json['scheduleDate']?.toString() ??
          json['schedule_date']?.toString() ??
          json['scheduledDate']?.toString() ??
          json['scheduled_date']?.toString() ??
          json['date']?.toString(),
    );
  }

  /// Converts this model into the exact display map required by Today page chat item tiles.
  Map<String, dynamic> toChatItem() {
    final statusLower = status.toLowerCase().trim();
    final formattedDate = (scheduleDate != null && scheduleDate!.isNotEmpty)
        ? scheduleDate!
        : (createdAt != null
            ? '${createdAt!.day.toString().padLeft(2, '0')}/${createdAt!.month.toString().padLeft(2, '0')}/${createdAt!.year}'
            : '');

    final avatarColors = getAvatarColorsForName(name);
    Color tagBg;
    Color tagText;

    switch (statusLower) {
      case 'completed':
        tagBg = AppColors.completedBg;
        tagText = AppColors.completedText;
        break;
      case 'cancelled':
        tagBg = AppColors.cancelledBg;
        tagText = AppColors.cancelledText;
        break;
      case 'scheduled':
        tagBg = const Color(0xFFFEF3C7);
        tagText = const Color(0xFFD97706);
        break;
      case 'new':
      default:
        tagBg = AppColors.newBg;
        tagText = AppColors.newText;
        break;
    }

    final locationStr = areaName.isNotEmpty
        ? areaName
        : (districtName.isNotEmpty ? districtName : address);

    return {
      'id': id.toString(),
      'title': name,
      'avatarLetter': name.isNotEmpty ? name[0].toUpperCase() : 'B',
      'avatarBgColor': avatarColors.background,
      'avatarTextColor': avatarColors.icon,
      'avatarBorderColor': null,
      'hasVerifiedBadge': false,
      'tagText': status.isNotEmpty
          ? '${status[0].toUpperCase()}${status.substring(1).toLowerCase()}'
          : 'New',
      'tagBgColor': tagBg,
      'tagTextColor': tagText,
      'location': locationStr,
      'date': formattedDate,
      'scheduleDate': scheduleDate ?? formattedDate,
      'unreadCount': 0,
      'isPending': statusLower != 'completed' && statusLower != 'cancelled',
      'branchHeadId': branchHeadId,
      'branchHeadName': branchHeadName,
      'branchManager': (branchHeadName != null && branchHeadName!.trim().isNotEmpty)
          ? branchHeadName!.trim()
          : (loginName ?? ''),
      'mobile': mobile,
      'notes': notes,
      'documents': documents,
      'booking': this,
      'searchIndex': '$name $status $locationStr $formattedDate'.toLowerCase(),
    };
  }
}
