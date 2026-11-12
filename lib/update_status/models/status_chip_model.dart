/// Data model representing a status filter chip returned by GET /api/status.
class StatusChipModel {
  final int id;
  final String code;
  final String label;
  final String? colorCode;
  final int sortOrder;
  final bool isActive;
  final bool isFollowUp;
  final bool isDate;

  const StatusChipModel({
    required this.id,
    required this.code,
    required this.label,
    this.colorCode,
    required this.sortOrder,
    required this.isActive,
    this.isFollowUp = false,
    this.isDate = false,
  });

  static bool _parseBoolFlag(dynamic val) =>
      val == 1 || val == true || val == '1';

  factory StatusChipModel.fromJson(Map<String, dynamic> json) {
    return StatusChipModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      code: json['code']?.toString().trim() ?? '',
      label: (json['label'] ?? json['code'] ?? '')?.toString().trim() ?? '',
      colorCode: (json['colorCode'] ?? json['statusColorCode'])?.toString(),
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder'] as int
          : int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
      isActive: _parseBoolFlag(json['isActive']),
      isFollowUp: _parseBoolFlag(json['isFollowUp'] ?? json['is_follow_up']),
      isDate: _parseBoolFlag(json['isDate'] ?? json['is_date']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'label': label,
    if (colorCode != null) ...{
      'colorCode': colorCode,
      'statusColorCode': colorCode,
    },
    'sortOrder': sortOrder,
    'isActive': isActive ? 1 : 0,
    'isFollowUp': isFollowUp ? 1 : 0,
    'isDate': isDate ? 1 : 0,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StatusChipModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          label == other.label;

  @override
  int get hashCode => id.hashCode ^ code.hashCode ^ label.hashCode;
}
