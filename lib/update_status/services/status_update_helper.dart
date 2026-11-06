import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../api/api.dart';
import '../../customer_details/customer_details_model.dart';
import '../../today/today_view_model.dart';
import '../branch_manager/branch_manager_update_status_logic.dart';

/// Shared helper that performs the status update POST and optional document sync PUT.
Future<bool> executeStatusUpdateSubmit({
  required http.Client client,
  required Map<String, String> headers,
  required StatusUpdateRequest requestPayload,
  required CustomerDetailsData customer,
  required String status,
  required String effectiveDate,
  required String notes,
  List<String>? documents,
}) async {
  final response = await client
      .post(
        Uri.parse(ApiConfig.statusUpdate),
        headers: headers,
        body: jsonEncode(requestPayload.toJson()),
      )
      .timeout(const Duration(seconds: 10));

  if (response.statusCode >= 200 && response.statusCode < 300) {
    if (documents != null && !listEquals(documents, customer.documents)) {
      try {
        final bookingUri = Uri.parse('${ApiConfig.bookings}/${customer.id}');
        await client
            .put(
              bookingUri,
              headers: headers,
              body: jsonEncode({'documents': documents}),
            )
            .timeout(const Duration(seconds: 10));
      } catch (_) {}
    }

    updateChatItemStatus(
      customerName: customer.name,
      newStatus: status,
      newDate: effectiveDate,
      newStaffNotes: notes.trim(),
    );
    return true;
  }
  return false;
}
