import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';
import '../api/authenticated_client.dart';
import '../login_page/token_storage.dart';
import '../update_status/status_update_result.dart';
import 'customer_details_model.dart';

/// ViewModel managing state, status updates, notes, and deletion for Customer Details screen.
class CustomerDetailsViewModel extends ChangeNotifier {
  final http.Client _client;
  final bool _isInternalClient;
  final TokenStorage? tokenStorage;
  CustomerDetailsModel customer;

  bool _isDeleting = false;
  String? _deleteError;
  bool _isUpdating = false;
  String? _updateError;

  CustomerDetailsViewModel({
    required this.customer,
    http.Client? client,
    this.tokenStorage,
  })  : _client = client ?? AuthenticatedClient(),
        _isInternalClient = client == null;

  http.Client get client => _client;
  bool get isDeleting => _isDeleting;
  String? get deleteError => _deleteError;
  bool get isUpdating => _isUpdating;
  String? get updateError => _updateError;

  /// Deletes customer booking from backend API (`DELETE /api/bookings/:id`).
  Future<bool> deleteCustomer() async {
    _isDeleting = true;
    _deleteError = null;
    notifyListeners();

    try {
      String? token;
      try {
        final isTest = TokenStorage.isTestEnvironment;
        token = await (tokenStorage ?? TokenStorage())
            .getToken()
            .timeout(isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 5));
      } catch (_) {}

      final uri = Uri.parse('${ApiConfig.bookings}/${customer.id}');
      final headers = <String, String>{
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization':
              token.startsWith('Bearer ') ? token : 'Bearer $token',
      };

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        String msg = 'Failed to delete customer (${response.statusCode})';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['error'] != null) {
              msg = decoded['error'].toString();
            } else if (decoded['message'] != null) {
              msg = decoded['message'].toString();
            }
          }
        } catch (_) {}
        _deleteError = msg;
        return false;
      }
    } catch (e) {
      _deleteError = 'Connection error';
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Updates customer booking on backend API (`PUT /api/bookings/:id`).
  Future<bool> updateCustomer({
    String? name,
    String? phoneNumber,
    String? address,
    String? notes,
    String? status,
    List<String>? documents,
  }) async {
    _isUpdating = true;
    _updateError = null;
    notifyListeners();

    try {
      String? token;
      try {
        final isTest = TokenStorage.isTestEnvironment;
        token = await (tokenStorage ?? TokenStorage())
            .getToken()
            .timeout(isTest ? const Duration(milliseconds: 50) : const Duration(seconds: 5));
      } catch (_) {}

      final uri = Uri.parse('${ApiConfig.bookings}/${customer.id}');
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty)
          'authorization':
              token.startsWith('Bearer ') ? token : 'Bearer $token',
      };

      final updatedName = name ?? customer.name;
      final updatedPhone = phoneNumber ?? customer.phoneNumber;
      final updatedAddress = address ??
          (customer.addressLine2.isNotEmpty
              ? '${customer.addressLine1}, ${customer.addressLine2}'
              : customer.addressLine1);
      final updatedNotes = notes ?? customer.notes;
      final updatedStatus = status ?? customer.status;
      final updatedDocs = documents ?? customer.documents;

      final body = jsonEncode({
        'name': updatedName,
        'mobile': updatedPhone,
        'address': updatedAddress,
        'notes': updatedNotes,
        'status': updatedStatus.toUpperCase(),
        'documents': updatedDocs,
      });

      final response = await _client
          .put(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        customer = customer.copyWith(
          name: updatedName,
          phoneNumber: updatedPhone,
          addressLine1: updatedAddress,
          addressLine2: '',
          notes: updatedNotes,
          status: updatedStatus,
          documents: updatedDocs,
        );
        notifyListeners();
        return true;
      } else {
        String msg = 'Failed to update contact (${response.statusCode})';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            if (decoded['error'] != null) {
              msg = decoded['error'].toString();
            } else if (decoded['message'] != null) {
              msg = decoded['message'].toString();
            }
          }
        } catch (_) {}
        _updateError = msg;
        return false;
      }
    } catch (e) {
      _updateError = 'Connection error';
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Updates the status and optional schedule date of the customer.
  void updateStatus(String newStatus, {String? scheduleDate}) {
    final wasScheduled = newStatus.toLowerCase() == 'scheduled' ||
        customer.hasBeenScheduled;
    customer = customer.copyWith(
      status: newStatus,
      scheduleDate: scheduleDate ?? customer.scheduleDate,
      hasBeenScheduled: wasScheduled,
    );
    notifyListeners();
  }

  /// Applies a full status update result from Update Status page.
  void applyUpdate(StatusUpdateResult result) {
    final wasScheduled = result.status.toLowerCase() == 'scheduled' ||
        customer.hasBeenScheduled;
    customer = customer.copyWith(
      status: result.status,
      scheduleDate: result.scheduleDate.isNotEmpty
          ? result.scheduleDate
          : customer.scheduleDate,
      notes: result.notes.isNotEmpty ? result.notes : customer.notes,
      documents: result.documents.isNotEmpty
          ? result.documents
          : customer.documents,
      branchHeadName: result.branchManager ?? customer.branchHeadName,
      hasBeenScheduled: wasScheduled,
    );
    notifyListeners();
  }

  /// Updates notes on the customer model.
  void updateNotes(String newNotes) {
    customer = customer.copyWith(notes: newNotes);
    notifyListeners();
  }

  @override
  void dispose() {
    if (_isInternalClient) {
      _client.close();
    }
    super.dispose();
  }
}
