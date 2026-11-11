import 'dart:convert';
import '../today/today_model.dart';

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
  final String staffNotes;
  final bool hasBeenScheduled;
  final List<String> documents;
  final int? branchHeadId;
  final String? branchHeadName;

  final String? scheduleDate;
  final String? statusColorCode;

  /// Returns the scheduled date formatted as day/month/year (DD/MM/YYYY).
  String get formattedScheduleDate => formatDateToDayMonthYear(scheduleDate);

  /// Convenient getter for the primary location/address.
  String get location => addressLine1.isNotEmpty ? addressLine1 : addressLine2;


  const CustomerDetailsModel({
    required this.id,
    required this.name,
    required this.inquiry,
    required this.status,
    required this.phoneNumber,
    required this.addressLine1,
    required this.addressLine2,
    this.notes = '',
    this.staffNotes = '',
    this.hasBeenScheduled = false,
    this.documents = const [],
    this.branchHeadId,
    this.branchHeadName,
    this.scheduleDate,
    this.statusColorCode,
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
    String? staffNotes,
    bool? hasBeenScheduled,
    List<String>? documents,
    int? branchHeadId,
    String? branchHeadName,
    String? scheduleDate,
    String? statusColorCode,
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
      staffNotes: staffNotes ?? this.staffNotes,
      hasBeenScheduled: hasBeenScheduled ?? this.hasBeenScheduled,
      documents: documents ?? this.documents,
      branchHeadId: branchHeadId ?? this.branchHeadId,
      branchHeadName: branchHeadName ?? this.branchHeadName,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      statusColorCode: statusColorCode ?? this.statusColorCode,
    );
  }

  /// Factory to generate customer details dynamically based on chat item.
  factory CustomerDetailsModel.fromChatInfo({
    required String name,
    String? location,
    String? tagText,
    String? id,
    List<String>? documents,
    int? branchHeadId,
    String? branchHeadName,
    String? scheduleDate,
    String? phoneNumber,
    String? notes,
    String? staffNotes,
    String? inquiry,
    String? statusColorCode,
  }) {
    final resolvedStatus =
        (tagText != null && tagText.isNotEmpty) ? tagText : 'New';

    final isScheduledOrCompleted =
        resolvedStatus.toLowerCase() == 'scheduled' ||
        resolvedStatus.toLowerCase() == 'completed';

    return CustomerDetailsModel(
      id: id ?? 'cust_default',
      name: name,
      inquiry: inquiry ?? '5ft Steel door enquiry',
      status: resolvedStatus,
      phoneNumber: (phoneNumber != null && phoneNumber.isNotEmpty)
          ? phoneNumber
          : '7096797345',
      addressLine1: location != null && location.isNotEmpty
          ? '742 Evergreen Terrace, $location'
          : '742 Evergreen Terrace',
      addressLine2: 'Springfield, OR 97477',
      notes: notes ?? '',
      staffNotes: staffNotes ?? '',
      hasBeenScheduled: isScheduledOrCompleted,
      documents: documents ?? const [],
      branchHeadId: branchHeadId,
      branchHeadName: branchHeadName,
      scheduleDate: scheduleDate,
      statusColorCode: statusColorCode,
    );
  }

  /// Factory to generate customer details from a BookingModel.
  factory CustomerDetailsModel.fromBooking(BookingModel booking) {
    final locationStr = booking.areaName.isNotEmpty
        ? booking.areaName
        : (booking.districtName.isNotEmpty
            ? booking.districtName
            : booking.address);

    final resolvedStatus =
        booking.status.isNotEmpty ? booking.status : 'New';
    final isScheduledOrCompleted =
        resolvedStatus.toLowerCase() == 'scheduled' ||
        resolvedStatus.toLowerCase() == 'completed';

    return CustomerDetailsModel(
      id: booking.id.toString(),
      name: booking.name.isNotEmpty ? booking.name : 'Booking #${booking.id}',
      inquiry: '5ft Steel door enquiry',
      status: resolvedStatus,
      phoneNumber: booking.mobile.isNotEmpty ? booking.mobile : '7096797345',
      addressLine1: locationStr.isNotEmpty
          ? '742 Evergreen Terrace, $locationStr'
          : '742 Evergreen Terrace',
      addressLine2: booking.stateName.isNotEmpty
          ? '${booking.stateName}, India'
          : 'Springfield, OR 97477',
      notes: booking.notes,
      staffNotes: booking.staffNotes,
      hasBeenScheduled: isScheduledOrCompleted,
      documents: booking.documents,
      branchHeadId: booking.branchHeadId,
      branchHeadName: booking.branchHeadName,
      scheduleDate: booking.scheduleDate,
      statusColorCode: booking.statusColorCode,
    );
  }

  /// Factory to generate customer details from a push notification payload.
  factory CustomerDetailsModel.fromNotificationData(Map<String, dynamic> data) {
    final bookingId = (data['bookingId'] ??
            data['booking_id'] ??
            data['bookingID'] ??
            data['id'] ??
            data['booking'])
        ?.toString();

    final name = (data['customerName'] ??
            data['customer_name'] ??
            data['clientName'] ??
            data['client_name'] ??
            data['booking_name'] ??
            data['name'] ??
            data['title'])
        ?.toString();

    final status = (data['status'] ??
            data['new_status_label'] ??
            data['new_status_code'] ??
            data['tag'] ??
            data['tagText'])
        ?.toString();

    final phone = (data['mobile'] ??
            data['phone'] ??
            data['phoneNumber'] ??
            data['phone_number'])
        ?.toString();

    final location = (data['location'] ??
            data['area'] ??
            data['areaName'] ??
            data['area_name'] ??
            data['district'] ??
            data['districtName'] ??
            data['district_name'] ??
            data['address'])
        ?.toString();

    final notes = (data['notes'] ??
            data['customer_note'] ??
            data['customerNotes'] ??
            data['note'] ??
            data['body'])
        ?.toString();

    final staffNotes = (data['staffNotes'] ??
            data['staff_note'] ??
            data['staffNote'])
        ?.toString();

    final scheduleDate = (data['scheduleDate'] ??
            data['schedule_date'] ??
            data['date'])
        ?.toString();

    final colorCode = (data['statusColorCode'] ??
            data['status_color_code'] ??
            data['new_status_color_code'] ??
            data['colorCode'] ??
            data['color_code'])
        ?.toString();

    final branchHeadId = data['branchHeadId'] is int
        ? data['branchHeadId'] as int
        : int.tryParse(data['branch_head_id']?.toString() ??
            data['branchHeadId']?.toString() ??
            '');

    final branchHeadName = (data['branchHeadName'] ??
            data['branch_head_name'] ??
            data['branchManager'] ??
            data['branch_manager'])
        ?.toString();

    List<String> documents = [];
    final rawDocs = data['documents'];
    if (rawDocs is List) {
      documents = rawDocs.map((e) => e.toString()).toList();
    } else if (rawDocs is String && rawDocs.isNotEmpty) {
      if (rawDocs.startsWith('[') && rawDocs.endsWith(']')) {
        try {
          final parsed = jsonDecode(rawDocs);
          if (parsed is List) {
            documents = parsed.map((e) => e.toString()).toList();
          }
        } catch (_) {
          documents = [rawDocs];
        }
      } else {
        documents = rawDocs.split(',').map((e) => e.trim()).toList();
      }
    }

    final id = (bookingId != null && bookingId.isNotEmpty)
        ? bookingId
        : 'booking_${DateTime.now().millisecondsSinceEpoch}';

    final displayName = (name != null && name.isNotEmpty)
        ? name
        : (bookingId != null ? 'Booking #$bookingId' : 'Customer Booking');

    return CustomerDetailsModel.fromChatInfo(
      id: id,
      name: displayName,
      location: location,
      tagText: (status != null && status.isNotEmpty) ? status : 'New',
      phoneNumber: phone,
      notes: notes,
      staffNotes: staffNotes,
      scheduleDate: scheduleDate,
      statusColorCode: colorCode,
      documents: documents,
      branchHeadId: branchHeadId,
      branchHeadName: branchHeadName,
    );
  }
}

/// Backward compatibility alias for CustomerDetailsModel.
typedef CustomerDetailsData = CustomerDetailsModel;
