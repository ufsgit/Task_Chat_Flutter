/// Data model representing a Lead.
class LeadFormData {
  final String name;
  final String mobile;
  final String address;
  final String notes;
  final String stage;

  const LeadFormData({
    this.name = '',
    this.mobile = '',
    this.address = '',
    this.notes = '',
    this.stage = 'New Lead',
  });

  LeadFormData copyWith({
    String? name,
    String? mobile,
    String? address,
    String? notes,
    String? stage,
  }) {
    return LeadFormData(
      name: name ?? this.name,
      mobile: mobile ?? this.mobile,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      stage: stage ?? this.stage,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'mobile': mobile,
    'address': address,
    'notes': notes,
    'stage': stage,
  };

  factory LeadFormData.fromJson(Map<String, dynamic> json) => LeadFormData(
    name: json['name'] as String? ?? '',
    mobile: json['mobile'] as String? ?? '',
    address: json['address'] as String? ?? '',
    notes: json['notes'] as String? ?? '',
    stage: json['stage'] as String? ?? 'New Lead',
  );
}

/// Available pipeline stages for a lead.
const List<String> defaultLeadStages = ['New Booking', 'Contacted'];

/// Separated mock / initial lead data.
/// Later, replacing this with an API fetch or passing empty fields
/// will update the screen without touching the UI code.
const LeadFormData initialLeadData = LeadFormData(
  name: '',
  mobile: '',
  address: '',
  notes: '',
  stage: 'New Booking',
);
