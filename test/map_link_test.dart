import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/customer_details_view.dart';
import 'package:task_chat/customer_details/customer_details_view_model.dart';
import 'package:task_chat/customer_details/widgets/customer_header_card.dart';
import 'package:task_chat/new_booking/add_booking_view.dart';
import 'package:task_chat/new_booking/add_booking_view_model.dart';
import 'package:task_chat/new_booking/lead_data.dart';
import 'package:task_chat/new_booking/widgets/location_link_card.dart';
import 'package:task_chat/new_booking/widgets/map_location_picker_page.dart';
import 'package:task_chat/today/today_model.dart';

void main() {
  group('mapLink deserialization and mapping tests', () {
    test('BookingModel parses mapLink and map_link correctly from JSON', () {
      final jsonCamel = {
        'id': 101,
        'name': 'Ramesh Kumar',
        'mobile': '9876543210',
        'address': 'Kakkanad, Kochi',
        'notes': 'Urgent requirement',
        'status': 'New',
        'stateName': 'Kerala',
        'districtName': 'Ernakulam',
        'areaName': 'Kakkanad',
        'documents': <String>[],
        'mapLink': 'https://maps.google.com/?q=10.0159,76.3419',
      };

      final booking1 = BookingModel.fromJson(jsonCamel);
      expect(booking1.mapLink, 'https://maps.google.com/?q=10.0159,76.3419');

      final chatItem1 = booking1.toChatItem();
      expect(
        chatItem1['mapLink'],
        'https://maps.google.com/?q=10.0159,76.3419',
      );

      final customer1 = CustomerDetailsModel.fromBooking(booking1);
      expect(customer1.mapLink, 'https://maps.google.com/?q=10.0159,76.3419');

      final jsonSnake = {
        'id': 102,
        'name': 'Suresh',
        'mobile': '9876543211',
        'address': 'Palarivattom',
        'notes': '',
        'status': 'Scheduled',
        'stateName': 'Kerala',
        'districtName': 'Ernakulam',
        'areaName': 'Palarivattom',
        'documents': <String>[],
        'map_link': 'https://maps.app.goo.gl/xyz123',
      };

      final booking2 = BookingModel.fromJson(jsonSnake);
      expect(booking2.mapLink, 'https://maps.app.goo.gl/xyz123');

      final chatItem2 = booking2.toChatItem();
      expect(chatItem2['mapLink'], 'https://maps.app.goo.gl/xyz123');

      final customer2 = CustomerDetailsModel.fromBooking(booking2);
      expect(customer2.mapLink, 'https://maps.app.goo.gl/xyz123');
    });

    test(
      'CustomerDetailsModel parses mapLink from ChatInfo and NotificationData',
      () {
        final customerFromChat = CustomerDetailsModel.fromChatInfo(
          name: 'Arun',
          mapLink: 'https://maps.google.com/?q=11.2588,75.7804',
        );
        expect(
          customerFromChat.mapLink,
          'https://maps.google.com/?q=11.2588,75.7804',
        );

        final customerFromNotification =
            CustomerDetailsModel.fromNotificationData({
              'booking_id': '999',
              'clientName': 'Vijay',
              'mapLink': 'https://maps.google.com/?q=9.9312,76.2673',
            });
        expect(
          customerFromNotification.mapLink,
          'https://maps.google.com/?q=9.9312,76.2673',
        );
      },
    );
  });

  group('CustomerHeaderCard address clickability tests', () {
    testWidgets(
      'Address is NOT clickable and has no open-in-new icon when mapLink is null or empty',
      (WidgetTester tester) async {
        const customerNoMap = CustomerDetailsModel(
          id: '1',
          name: 'Test Customer',
          inquiry: 'Fitting',
          status: 'New',
          phoneNumber: '9876543210',
          addressLine1: '742 Evergreen Terrace',
          addressLine2: 'Kochi, Kerala',
          mapLink: null,
        );

        bool mapTapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomerHeaderCard(
                customer: customerNoMap,
                onMapTap: () {
                  mapTapped = true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('742 Evergreen Terrace'), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new_rounded), findsNothing);

        // Tap on address text
        await tester.tap(find.text('742 Evergreen Terrace'));
        await tester.pumpAndSettle();

        expect(mapTapped, isFalse);
      },
    );

    testWidgets(
      'Address is clickable and has open-in-new icon when mapLink is present',
      (WidgetTester tester) async {
        const customerWithMap = CustomerDetailsModel(
          id: '2',
          name: 'Test Customer Map',
          inquiry: 'Fitting',
          status: 'Scheduled',
          phoneNumber: '9876543210',
          addressLine1: 'Door No 4B, Marine Drive',
          addressLine2: 'Kochi, Kerala',
          mapLink: 'https://maps.google.com/?q=9.9816,76.2764',
        );

        bool mapTapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomerHeaderCard(
                customer: customerWithMap,
                onMapTap: () {
                  mapTapped = true;
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Door No 4B, Marine Drive'), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
        expect(find.byIcon(Icons.location_on), findsOneWidget);

        // Tap on address
        await tester.tap(find.text('Door No 4B, Marine Drive'));
        await tester.pumpAndSettle();

        expect(mapTapped, isTrue);
      },
    );

    testWidgets(
      'CustomerDetailsView displays clickable address for both coordinator and branch manager',
      (WidgetTester tester) async {
        const customer = CustomerDetailsModel(
          id: '3',
          name: 'Customer Both Views',
          inquiry: 'Steel Door',
          status: 'Scheduled',
          phoneNumber: '9876543210',
          addressLine1: 'Near Metro Station, Aluva',
          addressLine2: 'Ernakulam, Kerala',
          mapLink: 'https://maps.google.com/?q=10.1076,76.3516',
        );

        // Coordinator view
        await tester.pumpWidget(
          const MaterialApp(
            home: CustomerDetailsView(customer: customer, isCoordinator: true),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Near Metro Station, Aluva'), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);

        // Branch Manager view
        await tester.pumpWidget(
          const MaterialApp(
            home: CustomerDetailsView(customer: customer, isCoordinator: false),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Near Metro Station, Aluva'), findsOneWidget);
        expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
      },
    );
  });

  group('Create booking mapLink & location picker tests', () {
    test('LeadFormData serializes mapLink and map_link only when non-empty', () {
      const withLink = LeadFormData(
        name: 'Test',
        mobile: '9876543210',
        address: 'Kochi',
        areaId: 1,
        areaName: 'Edapally',
        mapLink: '  https://maps.app.goo.gl/9eNxYYkUb8cmRbXw8  ',
      );
      final jsonWith = withLink.toJson();
      expect(jsonWith['mapLink'], 'https://maps.app.goo.gl/9eNxYYkUb8cmRbXw8');
      expect(jsonWith['map_link'], 'https://maps.app.goo.gl/9eNxYYkUb8cmRbXw8');

      const withoutLink = LeadFormData(
        name: 'Test',
        mobile: '9876543210',
        address: 'Kochi',
        areaId: 1,
        areaName: 'Edapally',
        mapLink: '   ',
      );
      final jsonWithout = withoutLink.toJson();
      expect(jsonWithout.containsKey('mapLink'), isFalse);
      expect(jsonWithout.containsKey('map_link'), isFalse);

      final parsed = LeadFormData.fromJson({
        'name': 'Test',
        'mobile': '9876543210',
        'address': 'Kochi',
        'map_link': 'https://maps.google.com/?q=10.015900,76.341900',
      });
      expect(
        parsed.mapLink,
        'https://maps.google.com/?q=10.015900,76.341900',
      );
    });

    test('LocationHelper formats and parses Google Maps coordinates', () {
      final link = LocationHelper.formatGoogleMapsLink(10.0159, 76.3419);
      expect(link, 'https://maps.google.com/?q=10.015900,76.341900');

      final parsed = LocationHelper.tryParseLatLng(link);
      expect(parsed, isNotNull);
      expect(parsed!.latitude, closeTo(10.0159, 0.0001));
      expect(parsed.longitude, closeTo(76.3419, 0.0001));

      expect(
        LocationHelper.tryParseLatLng(
          'https://maps.app.goo.gl/9eNxYYkUb8cmRbXw8',
        ),
        isNull,
      );
    });

    testWidgets(
      'LocationLinkCard updates controller on Current Location tap',
      (WidgetTester tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LocationLinkCard(
                controller: controller,
                onFetchCurrentLocation: () async =>
                    'https://maps.google.com/?q=9.931233,76.267304',
              ),
            ),
          ),
        );

        expect(find.text('Location Link'), findsOneWidget);
        expect(find.text('Current Location'), findsOneWidget);
        expect(find.text('Pick on Map'), findsOneWidget);

        await tester.tap(find.text('Current Location'));
        await tester.pumpAndSettle();

        expect(
          controller.text,
          'https://maps.google.com/?q=9.931233,76.267304',
        );
      },
    );

    testWidgets(
      'AddBookingView shows Location Link for both Coordinator and Branch Manager',
      (WidgetTester tester) async {
        final mockClient = MockClient((request) async {
          return http.Response('{"data": []}', 200);
        });

        for (final isCoordinator in [true, false]) {
          final vm = AddBookingViewModel(client: mockClient);
          await tester.pumpWidget(
            MaterialApp(
              home: AddBookingView(
                isCoordinator: isCoordinator,
                viewModel: vm,
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Location Link'), findsOneWidget);
          expect(find.text('Current Location'), findsOneWidget);
          expect(find.text('Pick on Map'), findsOneWidget);
        }
      },
    );

    testWidgets(
      'EditCustomerView displays existing mapLink and saves updated mapLink',
      (WidgetTester tester) async {
        const customer = CustomerDetailsModel(
          id: '42',
          name: 'John Edit',
          inquiry: 'Steel Door',
          status: 'New',
          phoneNumber: '9876543210',
          addressLine1: 'Kochi',
          addressLine2: 'Kerala',
          mapLink: 'https://maps.app.goo.gl/oldlink',
        );

        EditCustomerData? saved;
        await tester.pumpWidget(
          MaterialApp(
            home: EditCustomerView(
              customer: customer,
              onSave: (data) => saved = data,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Location Link'), findsOneWidget);
        expect(find.text('https://maps.app.goo.gl/oldlink'), findsOneWidget);
        expect(find.text('Current Location'), findsOneWidget);
        expect(find.text('Pick on Map'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextField, 'https://maps.app.goo.gl/oldlink'),
          'https://maps.app.goo.gl/9eNxYYkUb8cmRbXw8',
        );
        await tester.ensureVisible(find.text('Save'));
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(saved, isNotNull);
        expect(
          saved!.mapLink,
          'https://maps.app.goo.gl/9eNxYYkUb8cmRbXw8',
        );
      },
    );

    test(
      'CustomerDetailsViewModel.updateCustomer sends mapLink and map_link in PUT body',
      () async {
        late Map<String, dynamic> sentBody;
        final mockClient = MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response('{}', 200);
        });

        final vm = CustomerDetailsViewModel(
          customer: const CustomerDetailsModel(
            id: '42',
            name: 'John Edit',
            inquiry: 'Steel Door',
            status: 'New',
            phoneNumber: '9876543210',
            addressLine1: 'Kochi',
            addressLine2: 'Kerala',
          ),
          client: mockClient,
        );

        final ok = await vm.updateCustomer(
          mapLink: 'https://maps.app.goo.gl/9eNxYYkUb8cmRbXw8',
        );
        expect(ok, isTrue);
        expect(
          sentBody['mapLink'],
          'https://maps.app.goo.gl/9eNxYYkUb8cmRbXw8',
        );
        expect(
          sentBody['map_link'],
          'https://maps.app.goo.gl/9eNxYYkUb8cmRbXw8',
        );
        expect(
          vm.customer.mapLink,
          'https://maps.app.goo.gl/9eNxYYkUb8cmRbXw8',
        );
      },
    );
  });
}
