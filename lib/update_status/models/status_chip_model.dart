/// Data model representing a status filter chip returned by GET /api/status.
class StatusChipModel {
  final int id;
  final String code;
  final String label;
  final String? colorCode;
  final int sortOrder;
  final bool isActive;

  const StatusChipModel({
    required this.id,
    required this.code,
    required this.label,
    this.colorCode,
    required this.sortOrder,
    required this.isActive,
  });

  factory StatusChipModel.fromJson(Map<String, dynamic> json) {
    return StatusChipModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? 0,
      code: json['code']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      colorCode: (json['statusColorCode'] ?? json['colorCode'])?.toString(),
      sortOrder: json['sortOrder'] is int
          ? json['sortOrder'] as int
          : int.tryParse(json['sortOrder']?.toString() ?? '') ?? 0,
      isActive: json['isActive'] == 1 ||
          json['isActive'] == true ||
          json['isActive'] == '1',
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
