/// Data model representing a Lead.
class LeadFormData {
  final String name;
  final String mobile;
  final String address;
  final String notes;
  final String stage;
  final int? areaId;
  final String? areaName;
  final int? districtId;
  final String? districtName;
  final String? district;
  final List<String> documents;

  const LeadFormData({
    this.name = '',
    this.mobile = '',
    this.address = '',
    this.notes = '',
    this.stage = 'NEW',
    this.areaId,
    this.areaName,
    this.districtId,
    this.districtName,
    this.district,
    this.documents = const [],
  });

  LeadFormData copyWith({
    String? name,
    String? mobile,
    String? address,
    String? notes,
    String? stage,
    int? areaId,
    String? areaName,
    int? districtId,
    String? districtName,
    String? district,
    List<String>? documents,
  }) {
    return LeadFormData(
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      stage: stage ?? this.stage,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      districtId: districtId ?? this.districtId,
      districtName: districtName ?? this.districtName,
      district: district ?? this.district,
      documents: documents ?? this.documents,
    );
  }

  Map<String, dynamic> toJson() {
    final effectiveDistrictName =
        (districtName != null && districtName!.isNotEmpty)
        ? districtName
        : district;

    return {
      'name': name,
      'mobile': mobile,
      'address': address,
      'notes': notes,
      'status': _formatStatus(stage),
      'areaId': areaId,
      'areaName': areaName ?? '',
      if (districtId != null && districtId! > 0) 'districtId': districtId,
      if (effectiveDistrictName != null &&
          effectiveDistrictName.isNotEmpty) ...{
        'districtName': effectiveDistrictName,
        'district': effectiveDistrictName,
      },
      'documents': documents,
    };
  }

  static String _formatStatus(String status) {
    final lower = status.toLowerCase().trim();
    if (lower == 'new booking' || lower == 'new lead' || lower == 'new') {
      return 'NEW';
    }
    return status.toUpperCase();
  }

  factory LeadFormData.fromJson(Map<String, dynamic> json) {
    final rawDocs = json['documents'];
    final docsList = rawDocs is List
        ? rawDocs.map((e) => e.toString()).toList()
        : <String>[];

    return LeadFormData(
      name: json['name'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      stage: json['status'] as String? ?? 'NEW',
      areaId: json['areaId'] is int
          ? json['areaId'] as int
          : int.tryParse(json['areaId']?.toString() ?? ''),
      areaName: json['areaName'] as String?,
      districtId: json['districtId'] is int
          ? json['districtId'] as int
          : int.tryParse(json['districtId']?.toString() ?? ''),
      districtName:
          json['districtName']?.toString() ?? json['district']?.toString(),
      district:
          json['district']?.toString() ?? json['districtName']?.toString(),
      documents: docsList,
    );
  }
}

/// Available pipeline stages for a lead.
const List<String> defaultLeadStages = ['New Booking'];

/// Separated mock / initial lead data.
/// Later, replacing this with an API fetch or passing empty fields
/// will update the screen without touching the UI code.
const LeadFormData initialLeadData = LeadFormData(
  name: '',
  mobile: '',
  address: '',
  notes: '',
  stage: 'New Booking',
  documents: [],
);
