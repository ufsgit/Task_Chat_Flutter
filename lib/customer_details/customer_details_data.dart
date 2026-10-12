/// Data models and provider for Customer Details.
/// Keeps data decoupled from the UI for easy backend/API integration.
class CustomerDetailsData {
  final String id;
  final String name;
  final String inquiry;
  final String statusBadge;
  final String phoneNumber;
  final String addressLine1;
  final String addressLine2;
  final String notes;

  const CustomerDetailsData({
    required this.id,
    required this.name,
    required this.inquiry,
    required this.statusBadge,
    required this.phoneNumber,
    required this.addressLine1,
    required this.addressLine2,
    required this.notes,
  });

  /// Factory to generate or lookup customer details dynamically based on chat item.
  factory CustomerDetailsData.fromChatInfo({
    required String name,
    String? location,
    String? tagText,
    String? id,
  }) {
    final customData = _predefinedCustomers[name.toLowerCase().trim()];
    if (customData != null) {
      return customData;
    }

    // Default fallback dynamically populating with the customer's name and location
    return CustomerDetailsData(
      id: id ?? 'cust_default',
      name: name,
      inquiry: '5ft Steel door enquiry',
      statusBadge: tagText != null && tagText.isNotEmpty
          ? '• $tagText Lead • Follow-up Due'
          : '• Active Lead • Follow-up Due',
      phoneNumber: '7096797345',
      addressLine1: location != null && location.isNotEmpty
          ? '742 Evergreen Terrace, $location'
          : '742 Evergreen Terrace',
      addressLine2: 'Springfield, OR 97477',
      notes:
          'Inquired about door. Prefers morning WhatsApp messages or phone calls between 10:00 AM – 12:00 PM. Scheduled site visit follow-up for this Friday.',
    );
  }
}

/// Predefined profiles matching the app's chat items.
final Map<String, CustomerDetailsData> _predefinedCustomers = {
  'arun': const CustomerDetailsData(
    id: '1',
    name: 'Arun',
    inquiry: '5ft Steel door enquiry',
    statusBadge: '• Active Lead • Follow-up Due',
    phoneNumber: '7096797345',
    addressLine1: '742 Evergreen Terrace',
    addressLine2: 'Springfield, OR 97477',
    notes:
        'Inquired about door. Prefers morning WhatsApp messages or phone calls between 10:00 AM – 12:00 PM. Scheduled site visit follow-up for this Friday.',
  ),
  'devika': const CustomerDetailsData(
    id: '2',
    name: 'Devika',
    inquiry: 'Premium wooden finish door',
    statusBadge: '• Completed • Review Pending',
    phoneNumber: '9845123490',
    addressLine1: 'Civil Line Road, Thrissur',
    addressLine2: 'Kerala, 680001',
    notes:
        'Installation completed yesterday. Client expressed satisfaction with finish. Requested catalog for balcony sliders.',
  ),
  'abhijith': const CustomerDetailsData(
    id: '3',
    name: 'Abhijith',
    inquiry: 'Modern sliding patio door',
    statusBadge: '• New Lead • Call Required',
    phoneNumber: '9744567812',
    addressLine1: 'Marine Drive, Kochi',
    addressLine2: 'Kerala, 682031',
    notes:
        'New inquiry received via website. Requires quotation for 3 sets of glass sliding doors with security mesh.',
  ),
  'syam': const CustomerDetailsData(
    id: '4',
    name: 'Syam',
    inquiry: 'Industrial fire-rated door',
    statusBadge: '• In-progress • Inspection Done',
    phoneNumber: '9447123987',
    addressLine1: 'Boat Jetty Road, Alleppey',
    addressLine2: 'Kerala, 688001',
    notes:
        'Site measurements collected by engineering team. Drawing submitted for client architect approval.',
  ),
  'ramesh': const CustomerDetailsData(
    id: '5',
    name: 'Ramesh',
    inquiry: 'Custom grill security door',
    statusBadge: '• Active Lead • Quote Sent',
    phoneNumber: '9895012345',
    addressLine1: 'Gandhi Nagar, Ernakulam',
    addressLine2: 'Kerala, 682020',
    notes:
        'Quotation shared on WhatsApp. Customer negotiating on bulk discount for two residential villas.',
  ),
};
