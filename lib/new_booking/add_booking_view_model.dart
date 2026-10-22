import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:task_chat/login_page/token_storage.dart';
import '../api/api.dart';
import 'area_view_model.dart';
import 'lead_data.dart';

/// Result state returned after attempting to save a booking.
class SaveBookingResult {
  final bool isSuccess;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  const SaveBookingResult.success([this.data])
      : isSuccess = true,
        errorMessage = null;

  const SaveBookingResult.failure(this.errorMessage)
      : isSuccess = false,
        data = null;
}

/// ViewModel managing state, validation, and API submission for creating a new booking.
class AddBookingViewModel extends ChangeNotifier {
  final http.Client _client;
  final AreaViewModel areaViewModel;

  bool _isSubmitting = false;
  String? _errorMessage;

  AddBookingViewModel({
    http.Client? client,
    AreaViewModel? areaViewModel,
  })  : _client = client ?? http.Client(),
        areaViewModel = areaViewModel ?? AreaViewModel(client: client);

  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;

  /// Validates lead form input before submitting.
  String? validate(LeadFormData data) {
    if (data.name.trim().isEmpty) {
      return 'Please enter customer name';
    }
    if (data.mobile.trim().isEmpty) {
      return 'Please enter mobile number';
    }
    if (data.address.trim().isEmpty) {
      return 'Please enter address';
    }
    return null;
  }

  /// Sends the booking data to POST ApiConfig.bookings.
  Future<SaveBookingResult> saveBooking(LeadFormData formData) async {
    final validationError = validate(formData);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return SaveBookingResult.failure(validationError);
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    String? token;
    try {
      token = await TokenStorage().getToken();
    } catch (_) {
      // Ignored if platform channel is absent in test environment
    }

    try {
      final uri = Uri.parse(ApiConfig.bookings);
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization': token.startsWith('Bearer ') ? token : 'Bearer $token',
      };

      final payload = formData.toJson();

      final response = await _client
          .post(
            uri,
            headers: headers,
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic>? responseData;
        try {
          if (response.body.isNotEmpty) {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic>) {
              responseData = decoded;
            }
          }
        } catch (_) {}

        _isSubmitting = false;
        notifyListeners();
        return SaveBookingResult.success(responseData);
      } else {
        String errorMsg = 'Failed to save booking (${response.statusCode})';
        try {
          if (response.body.isNotEmpty) {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic>) {
              errorMsg = decoded['error']?.toString() ??
                  decoded['message']?.toString() ??
                  errorMsg;
            }
          }
        } catch (_) {}

        _errorMessage = errorMsg;
        _isSubmitting = false;
        notifyListeners();
        return SaveBookingResult.failure(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Network error: $e';
      _errorMessage = errorMsg;
      _isSubmitting = false;
      notifyListeners();
      return SaveBookingResult.failure(errorMsg);
    }
  }
}
