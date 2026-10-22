import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/new_booking/add_booking_view.dart';
import 'package:task_chat/new_booking/add_booking_view_model.dart';
import 'package:task_chat/new_booking/area_model.dart';
import 'package:task_chat/new_booking/area_view_model.dart';
import 'package:task_chat/new_booking/lead_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return 'test_mock_token';
        }
        return null;
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
  });

  group('AddBookingViewModel POST /api/bookings MVVM Tests', () {
    test('validate checks for required fields', () {
      final viewModel = AddBookingViewModel();

      expect(
        viewModel.validate(const LeadFormData(name: '', mobile: '123', address: 'Kochi')),
        'Please enter customer name',
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '', address: 'Kochi')),
        'Please enter mobile number',
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '123', address: '')),
        'Please enter address',
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '123', address: 'Kochi')),
        isNull,
      );
    });

    test('saveBooking sends POST request with areaId, areaName, and documents', () async {
      late String sentBody;
      late Map<String, String> sentHeaders;

      final mockClient = MockClient((request) async {
        if (request.method == 'POST' && request.url.path.endsWith('/api/bookings')) {
          sentBody = request.body;
          sentHeaders = request.headers;
          return http.Response(
            jsonEncode({
              'id': 10,
              'name': 'Rahul',
              'status': 'NEW',
              'areaId': 1,
              'areaName': 'Edapally',
              'documents': [],
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final viewModel = AddBookingViewModel(client: mockClient);

      const formData = LeadFormData(
        name: 'Rahul Krishnan',
        mobile: '+91 94471 22334',
        address: 'House 12, MG Road',
        notes: 'Double door fitting',
        stage: 'NEW',
        areaId: 1,
        areaName: 'Edapally',
        documents: [],
      );

      final result = await viewModel.saveBooking(formData);

      expect(result.isSuccess, true);
      expect(viewModel.isSubmitting, false);
      expect(viewModel.errorMessage, isNull);

      final parsedBody = jsonDecode(sentBody) as Map<String, dynamic>;
      expect(parsedBody['name'], 'Rahul Krishnan');
      expect(parsedBody['mobile'], '+91 94471 22334');
      expect(parsedBody['address'], 'House 12, MG Road');
      expect(parsedBody['notes'], 'Double door fitting');
      expect(parsedBody['status'], 'NEW');
      expect(parsedBody['areaId'], 1);
      expect(parsedBody['areaName'], 'Edapally');
      expect(parsedBody['documents'], isEmpty);
      expect(sentHeaders['authorization'], 'Bearer test_mock_token');
    });

    test('saveBooking handles API error response gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'name, mobile, and address are required fields.'}),
          400,
        );
      });

      final viewModel = AddBookingViewModel(client: mockClient);
      const formData = LeadFormData(
        name: 'Incomplete',
        mobile: '123',
        address: 'Street',
      );

      final result = await viewModel.saveBooking(formData);

      expect(result.isSuccess, false);
      expect(viewModel.errorMessage, 'name, mobile, and address are required fields.');
    });

    test('saveBooking handles network exception', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Network unreachable');
      });

      final viewModel = AddBookingViewModel(client: mockClient);
      const formData = LeadFormData(
        name: 'Rahul',
        mobile: '123',
        address: 'Kochi',
      );

      final result = await viewModel.saveBooking(formData);

      expect(result.isSuccess, false);
      expect(viewModel.errorMessage, contains('Network unreachable'));
    });
  });

  group('add_booking view integration with AddBookingViewModel', () {
    testWidgets('Tapping Save triggers API post and passes areaId and areaName', (tester) async {
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/api/dropdowns')) {
          return http.Response(
            jsonEncode({
              'type': 'area',
              'count': 1,
              'data': [
                {'id': 2, 'name': 'Kakkanad'},
              ],
            }),
            200,
          );
        }
        if (request.method == 'POST' && request.url.path.endsWith('/api/bookings')) {
          return http.Response(
            jsonEncode({
              'id': 101,
              'status': 'NEW',
            }),
            201,
          );
        }
        return http.Response('Not Found', 404);
      });

      final areaVm = AreaViewModel(
        client: mockClient,
        initialArea: const AreaItem(id: 2, name: 'Kakkanad'),
      );
      final bookingVm = AddBookingViewModel(client: mockClient, areaViewModel: areaVm);

      LeadFormData? savedLead;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: add_booking(
              viewModel: bookingVm,
              initialData: const LeadFormData(
                name: 'John Doe',
                mobile: '9876543210',
                address: 'Infopark, Kakkanad',
                notes: 'Setup urgent',
              ),
              onSave: (lead) => savedLead = lead,
            ),
          ),
        ),
      );

      // Verify selected area is displayed
      expect(find.text('Kakkanad'), findsOneWidget);

      // Tap Save button
      await tester.ensureVisible(find.text('Save'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedLead, isNotNull);
      expect(savedLead!.name, 'John Doe');
      expect(savedLead!.areaId, 2);
      expect(savedLead!.areaName, 'Kakkanad');
      expect(savedLead!.stage, 'New Booking');
      expect(savedLead!.documents, isEmpty);
      expect(savedLead!.toJson()['status'], 'NEW');
      expect(savedLead!.toJson()['documents'], isEmpty);
    });
  });
}
