/// Data model for Customer Details.
/// Decoupled from hardcoded mock dictionaries for clean API usage.
class CustomerDetailsModel {
  final String id;
  final String name;
  final String inquiry;
  final String status;
  final String phoneNumber;
  final String addressLine1;
  final String addressLine2;
  final String notes;
  final bool hasBeenScheduled;
  final List<String> documents;

  const CustomerDetailsModel({
    required this.id,
    required this.name,
    required this.inquiry,
    required this.status,
    required this.phoneNumber,
    required this.addressLine1,
    required this.addressLine2,
    this.notes = '',
    this.hasBeenScheduled = false,
    this.documents = const [],
  });

  CustomerDetailsModel copyWith({
    String? id,
    String? name,
    String? inquiry,
    String? status,
    String? phoneNumber,
    String? addressLine1,
    String? addressLine2,
    String? notes,
    bool? hasBeenScheduled,
    List<String>? documents,
  }) {
    return CustomerDetailsModel(
      id: id ?? this.id,
      name: name ?? this.name,
      inquiry: inquiry ?? this.inquiry,
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      notes: notes ?? this.notes,
      hasBeenScheduled: hasBeenScheduled ?? this.hasBeenScheduled,
      documents: documents ?? this.documents,
    );
  }

  /// Factory to generate customer details dynamically based on chat item.
  factory CustomerDetailsModel.fromChatInfo({
    required String name,
    String? location,
    String? tagText,
    String? id,
    List<String>? documents,
  }) {
    final resolvedStatus =
        (tagText != null && tagText.isNotEmpty) ? tagText : 'New';

    final isScheduledOrCompleted =
        resolvedStatus.toLowerCase() == 'scheduled' ||
        resolvedStatus.toLowerCase() == 'completed';

    return CustomerDetailsModel(
      id: id ?? 'cust_default',
      name: name,
      inquiry: '5ft Steel door enquiry',
      status: resolvedStatus,
      phoneNumber: '7096797345',
      addressLine1: location != null && location.isNotEmpty
          ? '742 Evergreen Terrace, $location'
          : '742 Evergreen Terrace',
      addressLine2: 'Springfield, OR 97477',
      notes: '',
      hasBeenScheduled: isScheduledOrCompleted,
      documents: documents ?? const [],
    );
  }
}

/// Backward compatibility alias for CustomerDetailsModel.
typedef CustomerDetailsData = CustomerDetailsModel;
