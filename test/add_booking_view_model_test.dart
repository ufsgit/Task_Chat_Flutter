import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_chat/new_booking/add_booking_view.dart';
import 'package:task_chat/new_booking/add_booking_view_model.dart';
import 'package:task_chat/new_booking/model/area_model.dart';
import 'package:task_chat/new_booking/area_view_model.dart';
import 'package:task_chat/new_booking/district_view_model.dart';
import 'package:task_chat/new_booking/lead_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
    test('validate checks for required fields and valid mobile format', () {
      final viewModel = AddBookingViewModel();

      expect(
        viewModel.validate(const LeadFormData(name: '', mobile: '9876543210', address: 'Kochi', areaId: 1, areaName: 'Edapally')),
        'Please enter customer name',
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '', address: 'Kochi', areaId: 1, areaName: 'Edapally')),
        'Please enter mobile number',
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '   ', address: 'Kochi', areaId: 1, areaName: 'Edapally')),
        'Please enter mobile number',
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '12345', address: 'Kochi', areaId: 1, areaName: 'Edapally')),
        'Please enter a valid 10-digit mobile number',
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: 'abcdefghij', address: 'Kochi', areaId: 1, areaName: 'Edapally')),
        'Please enter a valid 10-digit mobile number',
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '9876543210', address: '', areaId: 1, areaName: 'Edapally')),
        'Please enter address',
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '9876543210', address: 'Kochi')),
        'Please select an area',
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '9876543210', address: 'Kochi', areaId: null, areaName: 'Edapally')),
        'Please select an area',
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '9876543210', address: 'Kochi', areaId: 1, areaName: 'Edapally')),
        isNull,
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '+91 94471 22334', address: 'Kochi', areaId: 1, areaName: 'Edapally')),
        isNull,
      );
      expect(
        viewModel.validate(const LeadFormData(name: 'Rahul', mobile: '09876543210', address: 'Kochi', areaId: 1, areaName: 'Edapally')),
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
        mobile: '9876543210',
        address: 'Street',
        areaId: 1,
        areaName: 'Edapally',
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
        mobile: '9876543210',
        address: 'Kochi',
        areaId: 1,
        areaName: 'Edapally',
      );

      final result = await viewModel.saveBooking(formData);

      expect(result.isSuccess, false);
      expect(viewModel.errorMessage, contains('Network unreachable'));
    });
  });

  group('DistrictViewModel MVVM Tests', () {
    test('initializes with default fallback districts', () {
      final vm = DistrictViewModel();
      expect(vm.districts, isNotEmpty);
      expect(vm.districts.first.name, 'Ernakulam');
      expect(vm.selectedDistrict?.name, 'Ernakulam');
    });

    test('fetchDistricts updates districts from API', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/dropdowns/districts')) {
          return http.Response(
            jsonEncode({
              'type': 'district',
              'page': 1,
              'limit': 20,
              'count': 3,
              'data': [
                {'id': 1, 'name': 'Ernakulam'},
                {'id': 2, 'name': 'Thiruvananthapuram'},
                {'id': 3, 'name': 'Kozhikode'},
              ],
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final vm = DistrictViewModel(client: mockClient);
      await vm.fetchDistricts();

      expect(vm.isLoading, false);
      expect(vm.errorMessage, isNull);
      expect(vm.districts.length, 3);
      expect(vm.districts.map((d) => d.name), containsAll(['Ernakulam', 'Thiruvananthapuram', 'Kozhikode']));
    });

    test('selectDistrictByName sets active district', () {
      final vm = DistrictViewModel();
      vm.selectDistrictByName('Kozhikode');
      expect(vm.selectedDistrictName, 'Kozhikode');

      vm.selectDistrictByName('Thrissur');
      expect(vm.selectedDistrictName, 'Thrissur');
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

    testWidgets('renders District dropdown when isCoordinator is true and selects district', (WidgetTester tester) async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/api/dropdowns/districts')) {
          return http.Response(
            jsonEncode({
              'type': 'district',
              'page': 1,
              'limit': 20,
              'count': 3,
              'data': [
                {'id': 1, 'name': 'Ernakulam'},
                {'id': 2, 'name': 'Thiruvananthapuram'},
                {'id': 3, 'name': 'Kozhikode'},
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/api/dropdowns/areas') || request.url.path.endsWith('/api/dropdowns')) {
          return http.Response(
            jsonEncode({
              'type': 'area',
              'page': 1,
              'limit': 20,
              'count': 1,
              'data': [
                {'id': 1, 'name': 'Edapally'},
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'status': 'success', 'data': {'id': 99}}), 200);
      });

      final areaVm = AreaViewModel(
        client: mockClient,
        initialArea: const AreaItem(id: 1, name: 'Edapally'),
      );
      final bookingVm = AddBookingViewModel(client: mockClient, areaViewModel: areaVm);

      LeadFormData? savedLead;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: add_booking(
              isCoordinator: true,
              viewModel: bookingVm,
              initialData: const LeadFormData(
                name: 'Jane Coordinator',
                mobile: '9998887776',
                address: 'Marine Drive, Kochi',
              ),
              onSave: (lead) => savedLead = lead,
            ),
          ),
        ),
      );

      // Verify District dropdown is present
      expect(find.byKey(const Key('district_selector_dropdown')), findsOneWidget);
      expect(find.text('District'), findsOneWidget);
      expect(find.text('Ernakulam'), findsOneWidget);

      // Tap District dropdown to open options
      await tester.tap(find.byKey(const Key('district_selector_dropdown')));
      await tester.pumpAndSettle();

      // Verify all 3 hardcoded districts are displayed
      expect(find.text('Thiruvananthapuram'), findsOneWidget);
      expect(find.text('Kozhikode'), findsOneWidget);

      // Select Kozhikode
      await tester.tap(find.text('Kozhikode').last);
      await tester.pumpAndSettle();

      expect(find.text('Kozhikode'), findsOneWidget);

      // Tap Save
      await tester.ensureVisible(find.text('Save'));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(savedLead, isNotNull);
      expect(savedLead!.district, 'Kozhikode');
      expect(savedLead!.toJson()['district'], 'Kozhikode');
    });

    testWidgets('does NOT render District dropdown when isCoordinator is false', (WidgetTester tester) async {
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final areaVm = AreaViewModel(client: mockClient);
      final bookingVm = AddBookingViewModel(client: mockClient, areaViewModel: areaVm);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: add_booking(
              isCoordinator: false,
              viewModel: bookingVm,
            ),
          ),
        ),
      );

      expect(find.byKey(const Key('district_selector_dropdown')), findsNothing);
      expect(find.text('District'), findsNothing);
    });

    test('AreaViewModel uses coordinator_area_listing when isCoordinator is true and parses response body', () async {
      String? requestedUrl;
      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(
          jsonEncode({
            'type': 'district',
            'page': 1,
            'limit': 20,
            'count': 5,
            'data': [
              {
                'id': 1,
                'name': 'Ernakulam',
              },
            ],
          }),
          200,
        );
      });

      final areaVm = AreaViewModel(client: mockClient, isCoordinator: true);
      await areaVm.fetchAreas(districtId: 1);

      expect(requestedUrl, contains('/api/dropdowns/areas'));
      expect(requestedUrl, contains('districtId=1'));
      expect(areaVm.areas.length, 1);
      expect(areaVm.areas.first.id, 1);
      expect(areaVm.areas.first.name, 'Ernakulam');
    });

    test('AreaViewModel uses area_listing when isCoordinator is false', () async {
      String? requestedUrl;
      final mockClient = MockClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(
          jsonEncode({
            'type': 'area',
            'page': 1,
            'limit': 20,
            'count': 1,
            'data': [
              {
                'id': 3,
                'name': 'Aluva',
              },
            ],
          }),
          200,
        );
      });

      final areaVm = AreaViewModel(client: mockClient, isCoordinator: false);
      await areaVm.fetchAreas();

      expect(requestedUrl, contains('/api/dropdowns?'));
      expect(requestedUrl, isNot(contains('/api/dropdowns/areas')));
      expect(areaVm.areas.length, 1);
      expect(areaVm.areas.first.id, 3);
      expect(areaVm.areas.first.name, 'Aluva');
    });
  });
}
