import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/customer_details_view_model.dart';

void main() {
  group('CustomerDetailsViewModel MVVM Tests', () {
    const initialCustomer = CustomerDetailsModel(
      id: '101',
      name: 'Rahul Krishnan',
      inquiry: 'Double door fitting',
      status: 'New',
      phoneNumber: '+91 94471 22334',
      addressLine1: 'House 12, MG Road',
      addressLine2: 'Edapally, Ernakulam Hub',
      notes: 'Initial enquiry',
    );

    test('CustomerDetailsViewModel initializes with customer', () {
      final vm = CustomerDetailsViewModel(customer: initialCustomer);
      expect(vm.customer.name, 'Rahul Krishnan');
      expect(vm.customer.status, 'New');
      expect(vm.customer.hasBeenScheduled, isFalse);
    });

    test('CustomerDetailsViewModel updates status and marks scheduled', () {
      final vm = CustomerDetailsViewModel(customer: initialCustomer);
      var notified = false;
      vm.addListener(() => notified = true);

      vm.updateStatus('Scheduled');
      expect(notified, isTrue);
      expect(vm.customer.status, 'Scheduled');
      expect(vm.customer.hasBeenScheduled, isTrue);
    });

    test('CustomerDetailsViewModel updates notes and notifies listeners', () {
      final vm = CustomerDetailsViewModel(customer: initialCustomer);
      var notified = false;
      vm.addListener(() => notified = true);

      vm.updateNotes('Client confirmed visit date');
      expect(notified, isTrue);
      expect(vm.customer.notes, 'Client confirmed visit date');
    });
  });
}
