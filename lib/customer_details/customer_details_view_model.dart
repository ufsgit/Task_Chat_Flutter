import 'package:flutter/material.dart';
import 'customer_details_model.dart';

/// ViewModel managing state, status updates, and notes for Customer Details screen.
class CustomerDetailsViewModel extends ChangeNotifier {
  CustomerDetailsModel customer;

  CustomerDetailsViewModel({required this.customer});

  /// Updates the status of the customer and updates scheduling flag accordingly.
  void updateStatus(String newStatus) {
    final wasScheduled = newStatus.toLowerCase() == 'scheduled' ||
        customer.hasBeenScheduled;
    customer = customer.copyWith(
      status: newStatus,
      hasBeenScheduled: wasScheduled,
    );
    notifyListeners();
  }

  /// Updates notes on the customer model.
  void updateNotes(String newNotes) {
    customer = customer.copyWith(notes: newNotes);
    notifyListeners();
  }
}
