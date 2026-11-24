import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/core/widgets/app_pill_notification.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/customer_details_view.dart';
import 'package:task_chat/customer_details/customer_details_view_model.dart';

void main() {
  final testCustomer = CustomerDetailsModel(
    id: '101',
    name: 'Old Customer Name',
    inquiry: 'Old Inquiry',
    status: 'Scheduled',
    phoneNumber: '9876543210',
    addressLine1: 'Old Address',
    addressLine2: 'Old Location',
    notes: 'Old Notes',
    staffNotes: '',
    hasBeenScheduled: true,
  );

  group('CustomerDetailsViewModel fetchCustomerDetails tests', () {
    test('sets fetchError to "Failed to update" and returns false on 500', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final vm = CustomerDetailsViewModel(
        customer: testCustomer,
        client: mockClient,
      );

      final success = await vm.fetchCustomerDetails();

      expect(success, isFalse);
      expect(vm.fetchError, 'Failed to update');
      expect(vm.customer.name, 'Old Customer Name');
    });

    test('sets fetchError to "Failed to update" and returns false on network exception', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Network drop');
      });

      final vm = CustomerDetailsViewModel(
        customer: testCustomer,
        client: mockClient,
      );

      final success = await vm.fetchCustomerDetails();

      expect(success, isFalse);
      expect(vm.fetchError, 'Failed to update');
      expect(vm.customer.name, 'Old Customer Name');
    });

    test('updates customer and clears fetchError on successful 200 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 101,
              'name': 'Realtime Updated Name',
              'status': 'Completed',
              'mobile': '9876543210',
              'address': 'Updated Street',
              'notes': 'Updated Requirements',
            },
          }),
          200,
        );
      });

      final vm = CustomerDetailsViewModel(
        customer: testCustomer,
        client: mockClient,
      );

      final success = await vm.fetchCustomerDetails();

      expect(success, isTrue);
      expect(vm.fetchError, isNull);
      expect(vm.customer.name, 'Realtime Updated Name');
      expect(vm.customer.status, 'Completed');
    });
  });

  group('CustomerDetailsView Failed to Update banner UI tests', () {
    testWidgets('shows temp banner "Failed to update" when fetching latest details fails', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Error', 500);
      });

      final vm = CustomerDetailsViewModel(
        customer: testCustomer,
        client: mockClient,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDetailsView(
            customer: testCustomer,
            viewModel: vm,
            autoFetch: true,
          ),
        ),
      );

      // Trigger post frame callback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(AppPillNotification), findsOneWidget);
      expect(find.text('Failed to update'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('pull-to-refresh triggers fetch and shows "Failed to update" banner on failure', (tester) async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        return http.Response('Timeout Error', 504);
      });

      final vm = CustomerDetailsViewModel(
        customer: testCustomer,
        client: mockClient,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerDetailsView(
            customer: testCustomer,
            viewModel: vm,
            autoFetch: false, // Don't auto-fetch, test manual pull-to-refresh
          ),
        ),
      );

      expect(find.byType(AppPillNotification), findsNothing);

      // Pull down to refresh
      await tester.fling(find.byType(SingleChildScrollView), const Offset(0, 300), 1000);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));

      expect(requestCount, greaterThan(0));
      expect(find.byType(AppPillNotification), findsOneWidget);
      expect(find.text('Failed to update'), findsOneWidget);
    });
  });
}
