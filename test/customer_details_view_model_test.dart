import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/customer_details_view.dart';
import 'package:task_chat/customer_details/customer_details_view_model.dart';
import 'package:task_chat/update_status/status_update_result.dart';

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

    test('CustomerDetailsViewModel deleteCustomer sends DELETE request to /api/bookings/:id', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        expect(request.url.path, '/api/bookings/101');
        return http.Response(jsonEncode({'message': 'Booking deleted successfully'}), 200);
      });

      final vm = CustomerDetailsViewModel(
        customer: initialCustomer,
        client: mockClient,
      );

      final success = await vm.deleteCustomer();
      expect(success, isTrue);
      expect(vm.isDeleting, isFalse);
      expect(vm.deleteError, isNull);
    });

    test('CustomerDetailsViewModel deleteCustomer handles error gracefully', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'DELETE');
        return http.Response(jsonEncode({'error': 'Booking not found or already deleted.'}), 404);
      });

      final vm = CustomerDetailsViewModel(
        customer: initialCustomer,
        client: mockClient,
      );

      final success = await vm.deleteCustomer();
      expect(success, isFalse);
      expect(vm.isDeleting, isFalse);
      expect(vm.deleteError, 'Booking not found or already deleted.');
    });

    testWidgets('Tapping Delete Contact opens dialog and executes deleteCustomer', (WidgetTester tester) async {
      int deleteCalls = 0;
      final mockClient = MockClient((request) async {
        if (request.method == 'DELETE') {
          deleteCalls++;
          return http.Response(jsonEncode({'message': 'Deleted'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final vm = CustomerDetailsViewModel(
        customer: initialCustomer,
        client: mockClient,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDetailsView(
            customer: initialCustomer,
            viewModel: vm,
          ),
        ),
      );

      // Open more menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Delete Contact
      expect(find.text('Delete Contact'), findsOneWidget);
      await tester.tap(find.text('Delete Contact'));
      await tester.pumpAndSettle();

      // Verify AlertDialog is visible
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Are you sure you want to delete Rahul Krishnan?'), findsOneWidget);

      // Tap Delete button in dialog
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(deleteCalls, 1);
    });

    test('CustomerDetailsViewModel updateCustomer sends PUT request to /api/bookings/:id', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, '/api/bookings/101');
        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        expect(decoded['name'], 'Rahul K');
        expect(decoded['mobile'], '+91 99999 88888');
        expect(decoded['address'], 'Kochi, Kerala');
        expect(decoded['notes'], 'Updated notes');
        expect(decoded['documents'], isEmpty);
        return http.Response(jsonEncode({'message': 'Booking updated successfully'}), 200);
      });

      final vm = CustomerDetailsViewModel(
        customer: initialCustomer,
        client: mockClient,
      );

      final success = await vm.updateCustomer(
        name: 'Rahul K',
        phoneNumber: '+91 99999 88888',
        address: 'Kochi, Kerala',
        notes: 'Updated notes',
      );

      expect(success, isTrue);
      expect(vm.isUpdating, isFalse);
      expect(vm.customer.name, 'Rahul K');
      expect(vm.customer.phoneNumber, '+91 99999 88888');
      expect(vm.customer.addressLine1, 'Kochi, Kerala');
      expect(vm.customer.notes, 'Updated notes');
    });

    testWidgets('Tapping Edit Contact opens edit dialog and executes updateCustomer on save', (WidgetTester tester) async {
      int putCalls = 0;
      final mockClient = MockClient((request) async {
        if (request.method == 'PUT') {
          putCalls++;
          return http.Response(jsonEncode({'message': 'Updated'}), 200);
        }
        return http.Response('Not Found', 404);
      });

      final vm = CustomerDetailsViewModel(
        customer: initialCustomer,
        client: mockClient,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDetailsView(
            customer: initialCustomer,
            viewModel: vm,
          ),
        ),
      );

      // Open more menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      // Tap Edit Contact
      expect(find.text('Edit Contact'), findsOneWidget);
      await tester.tap(find.text('Edit Contact'));
      await tester.pumpAndSettle();

      // Verify AlertDialog is visible
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Save'), findsOneWidget);

      // Enter updated name
      await tester.enterText(find.widgetWithText(TextField, 'Rahul Krishnan'), 'Rahul Updated');

      // Tap Save
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save'));
      await tester.pumpAndSettle();

      expect(putCalls, 1);
      expect(vm.customer.name, 'Rahul Updated');
    });

    test('CustomerDetailsViewModel applyUpdate updates status, date, notes and documents', () {
      final vm = CustomerDetailsViewModel(customer: initialCustomer);
      var notified = false;
      vm.addListener(() => notified = true);

      vm.applyUpdate(const StatusUpdateResult(
        status: 'Scheduled',
        scheduleDate: '10/28/2026',
        notes: 'Updated schedule notes from coordinator',
        documents: ['/uploads/doc1.pdf'],
        branchManager: 'Manager Bob',
      ));

      expect(notified, isTrue);
      expect(vm.customer.status, 'Scheduled');
      expect(vm.customer.scheduleDate, '10/28/2026');
      expect(vm.customer.notes, 'Updated schedule notes from coordinator');
      expect(vm.customer.documents, ['/uploads/doc1.pdf']);
      expect(vm.customer.branchHeadName, 'Manager Bob');
      expect(vm.customer.hasBeenScheduled, isTrue);
    });

    testWidgets('CustomerDetailsView displays Scheduled date chip when scheduleDate is present', (tester) async {
      const customerWithDate = CustomerDetailsModel(
        id: '102',
        name: 'Anita Roy',
        inquiry: 'Single door fitting',
        status: 'Scheduled',
        scheduleDate: '10/28/2026',
        phoneNumber: '+91 94471 99999',
        addressLine1: 'MG Road',
        addressLine2: 'Kochi',
      );

      final vm = CustomerDetailsViewModel(customer: customerWithDate);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDetailsView(
            customer: customerWithDate,
            viewModel: vm,
          ),
        ),
      );

      expect(find.text('Scheduled: 28/10/2026'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
    });

    testWidgets('CustomerDetailsView displays ISO date in day/month/year format', (tester) async {
      const customerWithIsoDate = CustomerDetailsModel(
        id: '103',
        name: 'tvmmm',
        inquiry: 'Steel door enquiry',
        status: 'Scheduled',
        scheduleDate: '2024-10-23T18:30:00.000Z',
        phoneNumber: '1234567890',
        addressLine1: 'aa',
        addressLine2: 'Kowdiar, Trivandrum, Kerala',
      );

      final vm = CustomerDetailsViewModel(customer: customerWithIsoDate);

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDetailsView(
            customer: customerWithIsoDate,
            viewModel: vm,
          ),
        ),
      );

      expect(find.text('Scheduled: ${customerWithIsoDate.formattedScheduleDate}'), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_rounded), findsOneWidget);
    });
  });
}
