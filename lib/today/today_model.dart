import '../core/status_color_service.dart';
export '../core/date_utils.dart';

/// Data model representing a booking lead from /api/booking.
class BookingModel {
  final int id;
  final String name;
  final String mobile;
  final String address;
  final String notes;
  final String staffNotes;
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
  final String? statusColorCode;

  BookingModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    required this.notes,
    this.staffNotes = '',
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
    this.statusColorCode,
  });

  BookingModel copyWith({
    int? id,
    String? name,
    String? mobile,
    String? address,
    String? notes,
    String? staffNotes,
    String? status,
    int? loginRoleId,
    int? loginId,
    String? loginName,
    int? branchHeadId,
    String? branchHeadName,
    int? stateId,
    String? stateName,
    int? districtId,
    String? districtName,
    int? areaId,
    String? areaName,
    List<String>? documents,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? scheduleDate,
    String? statusColorCode,
  }) {
    return BookingModel(
      id: id ?? this.id,
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      staffNotes: staffNotes ?? this.staffNotes,
      status: status ?? this.status,
      loginRoleId: loginRoleId ?? this.loginRoleId,
      loginId: loginId ?? this.loginId,
      loginName: loginName ?? this.loginName,
      branchHeadId: branchHeadId ?? this.branchHeadId,
      branchHeadName: branchHeadName ?? this.branchHeadName,
      stateId: stateId ?? this.stateId,
      stateName: stateName ?? this.stateName,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      statusColorCode: statusColorCode ?? this.statusColorCode,
    );
  }

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
      staffNotes: json['staffNotes']?.toString() ?? json['staff_notes']?.toString() ?? '',
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
      branchHeadName:
          json['branchHeadName']?.toString() ??
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
      scheduleDate:
          json['scheduleDate']?.toString() ??
          json['schedule_date']?.toString() ??
          json['scheduledDate']?.toString() ??
          json['scheduled_date']?.toString() ??
          json['date']?.toString(),
      statusColorCode: (json['statusColorCode'] ??
              json['status_color_code'] ??
              json['new_status_color_code'] ??
              json['colorCode'] ??
              json['color_code'])
          ?.toString(),
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

    final customColor = StatusColorService.parseHexColor(statusColorCode);
    final badgeColors = StatusColorService.getBadgeColors(
      status,
      customColor: customColor,
    );
    final avatarColors = StatusColorService.getAvatarColors(
      status,
      customColor: customColor,
    );

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
      'tagBgColor': badgeColors.bg,
      'tagTextColor': badgeColors.text,
      'statusColorCode': statusColorCode,
      'location': locationStr,
      'date': formattedDate,
      'scheduleDate': scheduleDate ?? formattedDate,
      'unreadCount': 0,
      'isPending': statusLower != 'completed' && statusLower != 'cancelled',
      'branchHeadId': branchHeadId,
      'branchHeadName': branchHeadName,
      'branchManager':
          (branchHeadName != null && branchHeadName!.trim().isNotEmpty)
          ? branchHeadName!.trim()
          : (loginName ?? ''),
      'mobile': mobile,
      'notes': notes,
      'documents': documents,
      'booking': this,
      'searchIndex':
          '$name $mobile $status $locationStr $formattedDate $notes $areaName $districtName'
              .toLowerCase(),
    };
  }
}
