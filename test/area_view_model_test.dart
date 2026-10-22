import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/new_booking/area_model.dart';
import 'package:task_chat/new_booking/area_view_model.dart';
import 'package:task_chat/new_booking/widgets/area_selector_dropdown.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return 'mock_token';
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

  group('Area Dropdown Model & MVVM Tests', () {
    const userDistrictApiResponse = '''
    {
      "type": "district",
      "count": 5,
      "data": [
        {
          "id": 1,
          "name": "Ernakulam Hub"
        }
      ]
    }
    ''';

    const areaApiResponse = '''
    {
      "type": "area",
      "count": 2,
      "data": [
        {
          "id": 1,
          "name": "Edapally"
        },
        {
          "id": 3,
          "name": "Aluva"
        }
      ]
    }
    ''';

    test('AreaDropdownResponse parses user district response correctly', () {
      final jsonMap = jsonDecode(userDistrictApiResponse) as Map<String, dynamic>;
      final response = AreaDropdownResponse.fromJson(jsonMap);

      expect(response.type, 'district');
      expect(response.count, 5);
      expect(response.data.length, 1);
      expect(response.data.first.id, 1);
      expect(response.data.first.name, 'Ernakulam Hub');
    });

    test('AreaDropdownResponse parses area response correctly', () {
      final jsonMap = jsonDecode(areaApiResponse) as Map<String, dynamic>;
      final response = AreaDropdownResponse.fromJson(jsonMap);

      expect(response.type, 'area');
      expect(response.count, 2);
      expect(response.data.length, 2);
      expect(response.data[0].name, 'Edapally');
      expect(response.data[1].name, 'Aluva');
    });

    test('AreaViewModel fetches areas successfully from API with type, page, limit', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['type'], 'area');
        expect(request.url.queryParameters['page'], '1');
        expect(request.url.queryParameters['limit'], '20');
        expect(request.url.queryParameters.containsKey('parentId'), false);
        return http.Response(areaApiResponse, 200, headers: {'content-type': 'application/json'});
      });

      final viewModel = AreaViewModel(client: mockClient);
      expect(viewModel.isLoading, false);
      expect(viewModel.areas, isEmpty);

      await viewModel.fetchAreas();

      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.areas.length, 2);
      expect(viewModel.areas.first.name, 'Edapally');
    });

    test('AreaViewModel sends search, page, limit and does not touch parentId', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['type'], 'area');
        expect(request.url.queryParameters['search'], 'Kochi');
        expect(request.url.queryParameters['page'], '2');
        expect(request.url.queryParameters['limit'], '10');
        expect(request.url.queryParameters.containsKey('parentId'), false);
        return http.Response(areaApiResponse, 200, headers: {'content-type': 'application/json'});
      });

      final viewModel = AreaViewModel(client: mockClient);
      await viewModel.fetchAreas(search: 'Kochi', page: 2, limit: 10);

      expect(viewModel.search, 'Kochi');
      expect(viewModel.page, 2);
      expect(viewModel.limit, 10);
      expect(viewModel.areas.length, 2);
    });

    test('AreaViewModel handles API server error gracefully', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final viewModel = AreaViewModel(client: mockClient);
      await viewModel.fetchAreas();

      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, contains('Failed to load areas (500)'));
      expect(viewModel.areas, isEmpty);
    });

    test('AreaViewModel handles network exception gracefully', () async {
      final mockClient = MockClient((request) async {
        throw Exception('Connection failed');
      });

      final viewModel = AreaViewModel(client: mockClient);
      await viewModel.fetchAreas();

      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, contains('Connection failed'));
      expect(viewModel.areas, isEmpty);
    });

    test('AreaViewModel selectArea, selectAreaById, and clearSelection', () {
      final viewModel = AreaViewModel();
      const area1 = AreaItem(id: 1, name: 'Edapally');

      viewModel.selectArea(area1);
      expect(viewModel.selectedArea, area1);
      expect(viewModel.selectedAreaId, 1);
      expect(viewModel.selectedAreaName, 'Edapally');

      viewModel.clearSelection();
      expect(viewModel.selectedArea, isNull);
      expect(viewModel.selectedAreaId, isNull);
    });
  });

  group('AreaSelectorDropdown Widget Tests', () {
    testWidgets('Renders loading indicator when isLoading is true', (tester) async {
      final completer = Completer<http.Response>();
      final mockClient = MockClient((request) => completer.future);
      final viewModel = AreaViewModel(client: mockClient);
      final future = viewModel.fetchAreas();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AreaSelectorDropdown(viewModel: viewModel),
          ),
        ),
      );

      expect(find.text('Loading areas...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(http.Response('{"type":"area","count":0,"data":[]}', 200));
      await future;
      await tester.pump();
    });

    testWidgets('Renders areas and allows selection in dropdown', (tester) async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'type': 'area',
            'count': 2,
            'data': [
              {'id': 1, 'name': 'Edapally'},
              {'id': 3, 'name': 'Aluva'},
            ],
          }),
          200,
        );
      });

      final viewModel = AreaViewModel(client: mockClient);
      await viewModel.fetchAreas();

      AreaItem? selectedArea;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AreaSelectorDropdown(
              viewModel: viewModel,
              onAreaSelected: (area) => selectedArea = area,
            ),
          ),
        ),
      );

      expect(find.text('Area'), findsOneWidget);
      expect(find.text('Select Area'), findsOneWidget);

      // Open dropdown
      await tester.tap(find.byKey(const Key('area_selector_dropdown')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Edapally
      expect(find.text('Edapally'), findsWidgets);
      await tester.tap(find.text('Edapally').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(viewModel.selectedArea?.name, 'Edapally');
      expect(selectedArea?.id, 1);
    });
  });
}
