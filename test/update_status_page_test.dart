import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_chat/api/api.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/login_page/login_model.dart';
import 'package:task_chat/login_page/token_storage.dart';
import 'package:task_chat/settings/settings_model.dart';
import 'package:task_chat/today/today_model.dart';
import 'package:task_chat/today/today_view_model.dart';
import 'package:task_chat/update_status/branch_manager/branch_manager_update_status_logic.dart';
import 'package:task_chat/update_status/branch_manager/branch_manager_update_status_view.dart';
import 'package:task_chat/update_status/branch_manager/branch_manager_update_status_view_model.dart';
import 'package:task_chat/update_status/coordinators/coordinator_update_status_logic.dart';
import 'package:task_chat/update_status/coordinators/coordinator_update_status_view.dart';
import 'package:task_chat/update_status/coordinators/coordinator_update_status_view_model.dart';
import 'package:task_chat/update_status/widgets/branch_manager_field_card.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TokenStorage.useMemoryOnly = true;
    TodayViewModel.resetSession();
    todayChatItems.clear();
  });

  tearDown(() {
    TokenStorage.useMemoryOnly = false;
    TodayViewModel.resetSession();
  });

  test(
    'StatusUpdateRequest serialization and deserialization matches API example',
    () {
      const jsonMap = {
        'clientId': 1,
        'clientName': 'Abhijith',
        'status': 'Scheduled',
        'scheduleDate': '10/24/2024',
        'staffNotes': 'Client confirmed fitting for tomorrow afternoon.',
        'createdBy': 4,
        'createdByName': 'Rajesh Menon',
      };

      final request = StatusUpdateRequest.fromJson(jsonMap);
      expect(request.clientId, 1);
      expect(request.clientName, 'Abhijith');
      expect(request.status, 'Scheduled');
      expect(request.scheduleDate, '10/24/2024');
      expect(request.notes, 'Client confirmed fitting for tomorrow afternoon.');
      expect(request.createdBy, 4);
      expect(request.createdByName, 'Rajesh Menon');

      final serialized = request.toJson();
      expect(serialized, equals(jsonMap));
    },
  );

  test('UpdateStatusVisibility hides schedule when cancelled or completed', () {
    const scheduledVis = UpdateStatusVisibility('Scheduled');
    expect(scheduledVis.showSchedule, isTrue);

    const completedVis = UpdateStatusVisibility('Completed');
    expect(completedVis.showSchedule, isFalse);

    const cancelledVis = UpdateStatusVisibility('Cancelled');
    expect(cancelledVis.showSchedule, isFalse);
  });

  test(
    'Setting status to Completed automatically assigns current date and hides schedule',
    () {
      const customer = CustomerDetailsData(
        id: '1',
        name: 'Test Customer',
        inquiry: 'Fitmate Inquiry',
        status: 'Scheduled',
        phoneNumber: '1234567890',
        addressLine1: 'Test',
        addressLine2: '',
        notes: '',
        hasBeenScheduled: true,
      );

      final vm = BranchManagerUpdateStatusViewModel(customer: customer);
      expect(vm.showSchedule, isTrue);

      vm.setStatus('Completed');
      expect(vm.showSchedule, isFalse);
      expect(vm.scheduleDate, equals(formatCurrentDate()));
      vm.dispose();

      final coordVm = CoordinatorUpdateStatusViewModel(customer: customer);
      expect(coordVm.showSchedule, isTrue);

      coordVm.setStatus('Completed');
      expect(coordVm.showSchedule, isFalse);
      expect(coordVm.scheduleDate, equals(formatCurrentDate()));
      coordVm.dispose();
    },
  );

  testWidgets(
    'UpdateStatusPage hides Schedule card when Cancelled is selected',
    (WidgetTester tester) async {
      const customer = CustomerDetailsData(
        id: '1',
        name: 'Test Customer',
        inquiry: 'Fitmate Inquiry',
        status: 'Scheduled',
        phoneNumber: '+91 9876543210',
        addressLine1: 'Kochi',
        addressLine2: 'Kerala',
        notes: '',
        hasBeenScheduled: true,
      );

      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/api/status')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 1, 'code': 'Scheduled', 'label': 'Scheduled', 'isFollowUp': true, 'isActive': true, 'sortOrder': 1},
                {'id': 2, 'code': 'Completed', 'label': 'Completed', 'isFollowUp': false, 'isActive': true, 'sortOrder': 2},
                {'id': 3, 'code': 'Cancelled', 'label': 'Cancelled', 'isFollowUp': false, 'isActive': true, 'sortOrder': 3},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' && request.url.path.endsWith('/api/status')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 1, 'code': 'Scheduled', 'label': 'Scheduled', 'isFollowUp': true, 'isActive': true, 'sortOrder': 1},
                {'id': 2, 'code': 'Completed', 'label': 'Completed', 'isFollowUp': false, 'isActive': true, 'sortOrder': 2},
                {'id': 3, 'code': 'Cancelled', 'label': 'Cancelled', 'isFollowUp': false, 'isActive': true, 'sortOrder': 3},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: UpdateStatusPage(customer: customer, client: mockClient),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Schedule'), findsOneWidget);

      await tester.tap(find.text('Cancelled'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule'), findsNothing);

      await tester.tap(find.text('Scheduled'));
      await tester.pumpAndSettle();

      expect(find.text('Schedule'), findsOneWidget);
    },
  );

  testWidgets('UpdateStatusPage posts to ApiConfig.statusUpdate on Save', (
    WidgetTester tester,
  ) async {
    // Setup stored user profile
    await UserProfileData.save(
      const UserModel(
        id: 4,
        username: 'rajesh_menon',
        name: 'Rajesh Menon',
        roleId: 2,
        role: 'Coordinator',
      ),
    );
    final storage = TokenStorage();
    await storage.savetoken('mock_test_token');

    // Add entry in todayChatItems
    todayChatItems.add({
      'title': 'Abhijith',
      'tagText': 'New',
      'isPending': true,
    });

    const customer = CustomerDetailsData(
      id: '1',
      name: 'Abhijith',
      inquiry: 'Fitmate Inquiry',
      status: 'Scheduled',
      phoneNumber: '+91 9876543210',
      addressLine1: 'Kochi',
      addressLine2: 'Kerala',
      notes: '',
      hasBeenScheduled: true,
    );

    http.Request? capturedRequest;
    final mockClient = MockClient((request) async {
      if (request.method == 'GET' && request.url.path.endsWith('/api/status')) {
        return http.Response(
          jsonEncode({
            'data': [
              {'id': 1, 'code': 'Scheduled', 'label': 'Scheduled', 'isFollowUp': true, 'isActive': true, 'sortOrder': 1},
              {'id': 2, 'code': 'Completed', 'label': 'Completed', 'isFollowUp': false, 'isActive': true, 'sortOrder': 2},
              {'id': 3, 'code': 'Cancelled', 'label': 'Cancelled', 'isFollowUp': false, 'isActive': true, 'sortOrder': 3},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      if (request.url.toString() == ApiConfig.statusUpdate) {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'clientId': 1,
            'clientName': 'Abhijith',
            'status': 'Scheduled',
            'scheduleDate': '10/24/2024',
            'notes': 'Fitting confirmed',
            'createdBy': 4,
            'createdByName': 'Rajesh Menon',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: UpdateStatusPage(
          customer: customer,
          client: mockClient,
          tokenStorage: storage,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Enter notes
    final notesField = find.byType(TextField);
    await tester.enterText(notesField, 'Fitting confirmed');
    await tester.pump();

    // Tap Save button
    final saveButton = find.widgetWithText(ElevatedButton, 'Save');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(capturedRequest, isNotNull);
    expect(capturedRequest!.method, 'POST');
    expect(capturedRequest!.url.toString(), ApiConfig.statusUpdate);
    expect(capturedRequest!.headers['authorization'], 'Bearer mock_test_token');

    final parsedBody =
        jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
    expect(parsedBody['clientId'], 1);
    expect(parsedBody['clientName'], 'Abhijith');
    expect(parsedBody['status'], 'Scheduled');
    expect(parsedBody['staffNotes'], 'Fitting confirmed');
    expect(parsedBody['createdBy'], 4);
    expect(parsedBody['createdByName'], 'Rajesh Menon');

    // Verify todayChatItems updated
    expect(todayChatItems.first['tagText'], 'Scheduled');
  });

  testWidgets(
    'CoordinatorUpdateStatusPage posts to ApiConfig.statusUpdate on Save',
    (WidgetTester tester) async {
      await UserProfileData.save(
        const UserModel(
          id: 10,
          username: 'super_admin',
          name: 'Super Coordinator',
          roleId: 1,
          role: 'Admin',
        ),
      );
      final storage = TokenStorage();
      await storage.savetoken('coord_token');

      const customer = CustomerDetailsData(
        id: '5',
        name: 'Client Five',
        inquiry: 'Fitting',
        status: 'Scheduled',
        phoneNumber: '+91 9999999999',
        addressLine1: 'Calicut',
        addressLine2: 'Kerala',
        notes: '',
        hasBeenScheduled: true,
      );

      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/api/status')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 1, 'code': 'Scheduled', 'label': 'Scheduled', 'isFollowUp': true, 'isActive': true, 'sortOrder': 1},
                {'id': 2, 'code': 'Completed', 'label': 'Completed', 'isFollowUp': false, 'isActive': true, 'sortOrder': 2},
                {'id': 3, 'code': 'Cancelled', 'label': 'Cancelled', 'isFollowUp': false, 'isActive': true, 'sortOrder': 3},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' && request.url.path.endsWith('/api/status')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 1, 'code': 'Scheduled', 'label': 'Scheduled', 'isFollowUp': true, 'isActive': true, 'sortOrder': 1},
                {'id': 2, 'code': 'Completed', 'label': 'Completed', 'isFollowUp': false, 'isActive': true, 'sortOrder': 2},
                {'id': 3, 'code': 'Cancelled', 'label': 'Cancelled', 'isFollowUp': false, 'isActive': true, 'sortOrder': 3},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST' &&
            request.url.toString() == ApiConfig.statusUpdate) {
          capturedRequest = request;
        }
        return http.Response(
          jsonEncode({'message': 'Status updated'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CoordinatorUpdateStatusPage(
            customer: customer,
            client: mockClient,
            tokenStorage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save button
      final saveButton = find.widgetWithText(ElevatedButton, 'Save');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'POST');
      expect(capturedRequest!.url.toString(), ApiConfig.statusUpdate);
      expect(capturedRequest!.headers['authorization'], 'Bearer coord_token');

      final parsedBody =
          jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(parsedBody['clientId'], 5);
      expect(parsedBody['clientName'], 'Client Five');
      expect(parsedBody['createdBy'], 10);
      expect(parsedBody['createdByName'], 'Super Coordinator');
    },
  );

  test(
    'BranchManagerUpdateStatusViewModel and CoordinatorUpdateStatusViewModel initialize and update state',
    () {
      const customer = CustomerDetailsData(
        id: '2',
        name: 'MVVM Lead',
        inquiry: 'Fitting',
        status: 'New',
        phoneNumber: '+91 1234567890',
        addressLine1: 'Ernakulam',
        addressLine2: 'Kerala',
        notes: '',
        hasBeenScheduled: false,
      );

      final bmViewModel = BranchManagerUpdateStatusViewModel(
        customer: customer,
      );
      expect(bmViewModel.selectedStatus, 'New');
      expect(bmViewModel.showSchedule, isTrue);
      expect(
        bmViewModel.availableOptions,
        isEmpty,
      );

      bmViewModel.setStatus('Cancelled');
      expect(bmViewModel.selectedStatus, 'Cancelled');
      expect(bmViewModel.showSchedule, isFalse);

      bmViewModel.setScheduleDate('11/01/2026');
      expect(bmViewModel.scheduleDate, '11/01/2026');
      bmViewModel.dispose();

      final coordViewModel = CoordinatorUpdateStatusViewModel(
        customer: customer,
      );
      expect(coordViewModel.selectedStatus, 'New');
      expect(coordViewModel.showSchedule, isTrue);
      expect(
        coordViewModel.availableOptions,
        isEmpty,
      );

      coordViewModel.setBranchManager('Ramesh Kumar');
      expect(coordViewModel.selectedBranchManager, 'Ramesh Kumar');
      coordViewModel.dispose();
    },
  );

  test('ApiConfig contains branch_head_listing and users endpoint', () {
    expect(
      ApiConfig.branch_head_listing,
      '${ApiConfig.baseUrl}/api/users/get_branch_heads_for_status_update',
    );
    expect(
      ApiConfig.branch_manager_listing,
      '${ApiConfig.baseUrl}/api/users/get_branch_heads_for_status_update',
    );
    expect(ApiConfig.users, '${ApiConfig.baseUrl}/api/users');
  });

  test(
    'CoordinatorUpdateStatusViewModel.loadBranchManagers loads users from GET /api/users?role=branch_head',
    () async {
      const customer = CustomerDetailsData(
        id: '3',
        name: 'Test Customer',
        inquiry: 'Fitting',
        status: 'Scheduled',
        phoneNumber: '+91 9999999999',
        addressLine1: 'Kochi',
        addressLine2: 'Kerala',
        notes: '',
        hasBeenScheduled: true,
      );

      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 101,
                'name': 'Kochi Branch Head',
                'username': 'kochi_head',
                'role': 'branch_head',
              },
              {
                'id': 102,
                'name': 'Calicut Branch Head',
                'username': 'calicut_head',
                'role': 'branch_head',
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final storage = TokenStorage();
      await storage.savetoken('test_coord_token');

      final vm = CoordinatorUpdateStatusViewModel(
        customer: customer,
        client: mockClient,
        tokenStorage: storage,
      );

      await vm.loadBranchManagers();

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.method, 'GET');
      expect(
        capturedRequest!.url.path,
        Uri.parse(ApiConfig.branch_head_listing).path,
      );
      expect(capturedRequest!.url.queryParameters['page'], '1');
      expect(capturedRequest!.url.queryParameters['limit'], '20');
      expect(
        capturedRequest!.headers['authorization'],
        'Bearer test_coord_token',
      );

      expect(vm.branchManagers.length, 2);
      expect(vm.branchManagers[0].name, 'Kochi Branch Head');
      expect(vm.branchManagers[1].name, 'Calicut Branch Head');
      expect(
        vm.availableManagers,
        equals(['Kochi Branch Head', 'Calicut Branch Head']),
      );
      expect(vm.selectedBranchManager, 'Kochi Branch Head');

      vm.dispose();
    },
  );

  testWidgets(
    'CoordinatorUpdateStatusView displays dynamically fetched branch managers in dropdown',
    (WidgetTester tester) async {
      const customer = CustomerDetailsData(
        id: '4',
        name: 'Dynamic BM Lead',
        inquiry: 'Fitting',
        status: 'Scheduled',
        phoneNumber: '+91 8888888888',
        addressLine1: 'Trivandrum',
        addressLine2: 'Kerala',
        notes: '',
        hasBeenScheduled: true,
      );

      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/api/status')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 1, 'code': 'Scheduled', 'label': 'Scheduled', 'isFollowUp': true, 'isActive': true, 'sortOrder': 1},
                {'id': 2, 'code': 'Completed', 'label': 'Completed', 'isFollowUp': false, 'isActive': true, 'sortOrder': 2},
                {'id': 3, 'code': 'Cancelled', 'label': 'Cancelled', 'isFollowUp': false, 'isActive': true, 'sortOrder': 3},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path == Uri.parse(ApiConfig.branch_head_listing).path) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 201,
                  'name': 'Arun Varma',
                  'username': 'arun_v',
                  'role': 'branch_head',
                },
                {
                  'id': 202,
                  'name': 'Sneha Nair',
                  'username': 'sneha_n',
                  'role': 'branch_head',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      final storage = TokenStorage();
      await storage.savetoken('mock_jwt_token');

      await tester.pumpWidget(
        MaterialApp(
          home: CoordinatorUpdateStatusView(
            customer: customer,
            client: mockClient,
            tokenStorage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify initial selection is dynamically set to first fetched manager
      expect(find.text('Arun Varma'), findsOneWidget);

      // Open dropdown menu
      await tester.tap(
        find.descendant(
          of: find.byType(BranchManagerFieldCard),
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      await tester.pumpAndSettle();

      // Both fetched managers should be listed
      expect(find.text('Sneha Nair'), findsOneWidget);

      // Select second manager
      await tester.tap(find.text('Sneha Nair').last);
      await tester.pumpAndSettle();

      expect(find.text('Sneha Nair'), findsOneWidget);
    },
  );

  testWidgets(
    'BranchManagerFieldCard opens dropdown on tapping anywhere on container and uses full width',
    (WidgetTester tester) async {
      String selected = 'Sarah Jenkins';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: BranchManagerFieldCard(
                selectedManager: selected,
                onManagerChanged: (val) => selected = val,
                managers: const ['Sarah Jenkins', 'Alex Morgan'],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify PopupMenuButton constraints have full width of parent
      final popupMenuFinder = find.byType(PopupMenuButton<String>);
      final popupMenuWidget = tester.widget<PopupMenuButton<String>>(
        popupMenuFinder,
      );
      expect(popupMenuWidget.constraints, isNotNull);
      expect(popupMenuWidget.constraints!.minWidth, greaterThan(0));
      expect(
        popupMenuWidget.constraints!.minWidth,
        equals(popupMenuWidget.constraints!.maxWidth),
      );

      // Tap directly on the container's label 'BRANCH MANAGER' (not on the arrow icon)
      await tester.tap(find.text('BRANCH MANAGER'));
      await tester.pumpAndSettle();

      // Dropdown menu items are visible
      expect(find.text('Alex Morgan'), findsOneWidget);

      // Tap option to select
      await tester.tap(find.text('Alex Morgan').last);
      await tester.pumpAndSettle();

      expect(selected, 'Alex Morgan');
    },
  );

  testWidgets(
    'CoordinatorUpdateStatusPage sets createdBy and createdByName to selected Branch Manager on Save',
    (WidgetTester tester) async {
      await UserProfileData.save(
        const UserModel(
          id: 3,
          username: 'alex_c',
          name: 'Alex George (Coordinator)',
          roleId: 1,
          role: 'Admin',
        ),
      );
      final storage = TokenStorage();
      await storage.savetoken('coord_token');

      const customer = CustomerDetailsData(
        id: '25',
        name: 'doctt ff',
        inquiry: 'Fitting',
        status: 'Scheduled',
        phoneNumber: '+91 9999999999',
        addressLine1: 'Kochi',
        addressLine2: 'Kerala',
        notes: '',
        hasBeenScheduled: true,
      );

      http.Request? capturedStatusRequest;
      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/api/status')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 1, 'code': 'Scheduled', 'label': 'Scheduled', 'isFollowUp': true, 'isActive': true, 'sortOrder': 1},
                {'id': 2, 'code': 'Completed', 'label': 'Completed', 'isFollowUp': false, 'isActive': true, 'sortOrder': 2},
                {'id': 3, 'code': 'Cancelled', 'label': 'Cancelled', 'isFollowUp': false, 'isActive': true, 'sortOrder': 3},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path == Uri.parse(ApiConfig.branch_head_listing).path) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 101,
                  'name': 'Kochi Branch Head',
                  'username': 'kochi_head',
                  'role': 'branch_head',
                },
                {
                  'id': 102,
                  'name': 'Calicut Branch Head',
                  'username': 'calicut_head',
                  'role': 'branch_head',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'POST' &&
            request.url.toString() == ApiConfig.statusUpdate) {
          capturedStatusRequest = request;
          return http.Response(
            jsonEncode({'success': true, 'message': 'Status updated'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      await tester.pumpWidget(
        MaterialApp(
          home: CoordinatorUpdateStatusView(
            customer: customer,
            client: mockClient,
            tokenStorage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Select 'Calicut Branch Head' (id: 102)
      await tester.tap(find.text('Kochi Branch Head'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calicut Branch Head').last);
      await tester.pumpAndSettle();

      // Tap Save
      final saveButton = find.widgetWithText(ElevatedButton, 'Save');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(capturedStatusRequest, isNotNull);
      final body =
          jsonDecode(capturedStatusRequest!.body) as Map<String, dynamic>;
      expect(body['createdBy'], 102);
      expect(body['createdByName'], 'Calicut Branch Head');
      expect(body['branchManager'], 'Calicut Branch Head');
      expect(body['branchManagerId'], 102);
    },
  );

  test(
    'BookingModel parses branchHeadName and branchHeadId from /api/bookings JSON',
    () {
      const bookingJson = {
        'id': 16,
        'name': 'file 2',
        'mobile': '4567876323',
        'address': 'sdf',
        'notes': 'sdfsadf',
        'status': 'SCHEDULED',
        'loginRoleId': 3,
        'loginId': 4,
        'loginName': 'Rajesh Menon',
        'stateId': 1,
        'stateName': 'Kerala',
        'districtId': 1,
        'districtName': 'Ernakulam',
        'branchHeadId': 4,
        'branchHeadName': 'Rajesh Menon',
        'documents': ['/uploads/test.pdf'],
      };

      final booking = BookingModel.fromJson(bookingJson);
      expect(booking.branchHeadId, 4);
      expect(booking.branchHeadName, 'Rajesh Menon');

      final chatItem = booking.toChatItem();
      expect(chatItem['branchHeadId'], 4);
      expect(chatItem['branchHeadName'], 'Rajesh Menon');
      expect(chatItem['branchManager'], 'Rajesh Menon');
    },
  );

  testWidgets(
    'CoordinatorUpdateStatusPage puts branchHeadName from /api/bookings as branch manager',
    (WidgetTester tester) async {
      const customer = CustomerDetailsData(
        id: '16',
        name: 'file 2',
        inquiry: 'sdfsadf',
        status: 'Scheduled',
        phoneNumber: '4567876323',
        addressLine1: 'sdf',
        addressLine2: 'Ernakulam, Kerala',
        notes: 'sdfsadf',
        hasBeenScheduled: true,
        branchHeadId: 4,
        branchHeadName: 'Rajesh Menon',
      );

      final mockClient = MockClient((request) async {
        if (request.method == 'GET' && request.url.path.endsWith('/api/status')) {
          return http.Response(
            jsonEncode({
              'data': [
                {'id': 1, 'code': 'Scheduled', 'label': 'Scheduled', 'isFollowUp': true, 'isActive': true, 'sortOrder': 1},
                {'id': 2, 'code': 'Completed', 'label': 'Completed', 'isFollowUp': false, 'isActive': true, 'sortOrder': 2},
                {'id': 3, 'code': 'Cancelled', 'label': 'Cancelled', 'isFollowUp': false, 'isActive': true, 'sortOrder': 3},
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        if (request.method == 'GET' &&
            request.url.path == Uri.parse(ApiConfig.branch_head_listing).path) {
          return http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 4,
                  'name': 'Rajesh Menon',
                  'username': 'branch_ekm',
                  'role': 'branch_head',
                },
                {
                  'id': 5,
                  'name': 'Suresh Kumar',
                  'username': 'branch_tvm',
                  'role': 'branch_head',
                },
              ],
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 200);
      });

      final storage = TokenStorage();
      await storage.savetoken('coord_token');

      await tester.pumpWidget(
        MaterialApp(
          home: CoordinatorUpdateStatusView(
            customer: customer,
            client: mockClient,
            tokenStorage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Branch Manager field card displays 'Rajesh Menon'
      expect(find.text('Rajesh Menon'), findsOneWidget);
    },
  );

  testWidgets(
    'BranchManagerUpdateStatusView hides delete document button but allows adding documents',
    (WidgetTester tester) async {
      const customer = CustomerDetailsData(
        id: '1',
        name: 'John Doe',
        inquiry: 'Fitmate Inquiry',
        phoneNumber: '9876543210',
        addressLine1: 'MG Road',
        addressLine2: 'Kochi',
        status: 'Scheduled',
        notes: '',
        documents: ['invoice.pdf'],
        branchHeadId: 2,
        branchHeadName: 'Branch Head User',
      );

      final mockClient = MockClient(
        (request) async => http.Response('{}', 200),
      );
      final storage = TokenStorage();
      await storage.savetoken('bm_token');

      await tester.pumpWidget(
        MaterialApp(
          home: BranchManagerUpdateStatusView(
            customer: customer,
            client: mockClient,
            tokenStorage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('invoice.pdf'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Add File'), findsOneWidget);
      // Delete icon is hidden for Branch Manager
      expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
    },
  );

  testWidgets(
    'CoordinatorUpdateStatusView displays delete document button and allows adding documents',
    (WidgetTester tester) async {
      const customer = CustomerDetailsData(
        id: '1',
        name: 'John Doe',
        inquiry: 'Fitmate Inquiry',
        phoneNumber: '9876543210',
        addressLine1: 'MG Road',
        addressLine2: 'Kochi',
        status: 'Scheduled',
        notes: '',
        documents: ['contract.pdf'],
        branchHeadId: 2,
        branchHeadName: 'Branch Head User',
      );

      final mockClient = MockClient(
        (request) async => http.Response('{}', 200),
      );
      final storage = TokenStorage();
      await storage.savetoken('coord_token');

      await tester.pumpWidget(
        MaterialApp(
          home: CoordinatorUpdateStatusView(
            customer: customer,
            client: mockClient,
            tokenStorage: storage,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('contract.pdf'), findsOneWidget);
      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Add File'), findsOneWidget);
      // Delete icon is visible for Coordinator
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    },
  );

  test('BranchHeadUser parses new backend schema and formats listingLabel', () {
    final jsonItem = {
      'branch_head_id': 10001,
      'branch_head_name': 'anu',
      'district_id': 7,
      'district_name': 'Ernakulam',
      'area_id': 90,
      'area_name': 'Cherai',
      'area_pincode': '683514',
      'display_label': 'anu (Ernakulam - Cherai)',
    };

    final user = BranchHeadUser.fromJson(jsonItem);
    expect(user.id, 10001);
    expect(user.name, 'anu');
    expect(user.districtId, 7);
    expect(user.districtName, 'Ernakulam');
    expect(user.areaId, 90);
    expect(user.areaName, 'Cherai');
    expect(user.areaPincode, '683514');
    expect(user.displayLabel, 'anu (Ernakulam - Cherai)');
    expect(user.listingLabel, 'anu (Ernakulam - Cherai) - 683514');
  });

  testWidgets(
    'BranchManagerFieldCard displays empty message inside dropdown box when managers list is empty',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BranchManagerFieldCard(
              selectedManager: '',
              onManagerChanged: (_) {},
              managers: const [],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No branch managers available'), findsOneWidget);
    },
  );

  test(
    'CoordinatorUpdateStatusViewModel loads new schema and formats display_label - pincode in availableManagers',
    () async {
      const customer = CustomerDetailsData(
        id: '1',
        name: 'Jane Doe',
        inquiry: 'Door Inquiry',
        phoneNumber: '9876543210',
        addressLine1: 'Marine Drive',
        addressLine2: 'Kochi',
        status: 'Scheduled',
        notes: '',
        documents: [],
      );

      final mockClient = MockClient((request) async {
        if (request.url.path == Uri.parse(ApiConfig.branch_head_listing).path) {
          return http.Response(
            json.encode({
              'success': true,
              'page': 1,
              'limit': 20,
              'count': 2,
              'data': [
                {
                  'branch_head_id': 10001,
                  'branch_head_name': 'anu',
                  'district_id': 7,
                  'district_name': 'Ernakulam',
                  'area_id': 90,
                  'area_name': 'Cherai',
                  'area_pincode': '683514',
                  'display_label': 'anu (Ernakulam - Cherai)',
                },
                {
                  'branch_head_id': 10002,
                  'branch_head_name': 'idukki',
                  'district_id': 6,
                  'district_name': 'Idukki',
                  'area_id': 65,
                  'area_name': 'Kumily',
                  'area_pincode': '685509',
                  'display_label': 'idukki (Idukki - Kumily)',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final storage = TokenStorage();
      await storage.savetoken('coord_token');

      final vm = CoordinatorUpdateStatusViewModel(
        customer: customer,
        client: mockClient,
        tokenStorage: storage,
      );

      await vm.loadBranchManagers();

      expect(vm.branchManagers.length, 2);
      expect(
        vm.availableManagers,
        equals([
          'anu (Ernakulam - Cherai) - 683514',
          'idukki (Idukki - Kumily) - 685509',
        ]),
      );
      expect(vm.selectedBranchManager, 'anu (Ernakulam - Cherai) - 683514');

      final head = vm.selectedBranchHead;
      expect(head, isNotNull);
      expect(head!.id, 10001);
      expect(head.name, 'anu');
      expect(head.districtId, 7);
      expect(head.districtName, 'Ernakulam');
    },
  );

  test(
    'CoordinatorUpdateStatusLogic.fetchBranchManagersPaginated sends page and limit query params',
    () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        if (request.url.path == Uri.parse(ApiConfig.branch_head_listing).path) {
          capturedRequest = request;
          return http.Response(
            json.encode({
              'success': true,
              'page': int.parse(request.url.queryParameters['page'] ?? '1'),
              'limit': int.parse(request.url.queryParameters['limit'] ?? '20'),
              'count': 35,
              'data': [
                {
                  'branch_head_id': 1,
                  'branch_head_name': 'Manager 1',
                  'display_label': 'Manager 1 (TVM)',
                  'area_pincode': '695001',
                },
              ],
            }),
            200,
          );
        }
        return http.Response('{}', 200);
      });

      final logic = CoordinatorUpdateStatusLogic(
        client: mockClient,
        tokenStorage: TokenStorage(),
      );

      final result = await logic.fetchBranchManagersPaginated(
        page: 1,
        limit: 20,
      );

      expect(capturedRequest, isNotNull);
      expect(capturedRequest!.url.queryParameters['page'], '1');
      expect(capturedRequest!.url.queryParameters['limit'], '20');
      expect(result.page, 1);
      expect(result.limit, 20);
      expect(result.count, 35);
      expect(result.hasMore, isTrue);
      expect(result.users.length, 1);
      expect(result.users[0].listingLabel, 'Manager 1 (TVM) - 695001');
    },
  );

  test(
    'CoordinatorUpdateStatusViewModel paginates branch managers on loadNextBranchManagersPage',
    () async {
      const customer = CustomerDetailsData(
        id: '1',
        name: 'Jane Doe',
        inquiry: 'Door Inquiry',
        phoneNumber: '9876543210',
        addressLine1: 'Marine Drive',
        addressLine2: 'Kochi',
        status: 'Scheduled',
        notes: '',
        documents: [],
      );

      final mockClient = MockClient((request) async {
        if (request.url.path == Uri.parse(ApiConfig.branch_head_listing).path) {
          final page = int.parse(request.url.queryParameters['page'] ?? '1');
          if (page == 1) {
            return http.Response(
              json.encode({
                'success': true,
                'page': 1,
                'limit': 2,
                'count': 4,
                'data': [
                  {
                    'branch_head_id': 101,
                    'branch_head_name': 'BM 1',
                    'display_label': 'BM 1 (EKM)',
                    'area_pincode': '682001',
                  },
                  {
                    'branch_head_id': 102,
                    'branch_head_name': 'BM 2',
                    'display_label': 'BM 2 (EKM)',
                    'area_pincode': '682002',
                  },
                ],
              }),
              200,
            );
          } else if (page == 2) {
            return http.Response(
              json.encode({
                'success': true,
                'page': 2,
                'limit': 2,
                'count': 4,
                'data': [
                  {
                    'branch_head_id': 103,
                    'branch_head_name': 'BM 3',
                    'display_label': 'BM 3 (KZD)',
                    'area_pincode': '673001',
                  },
                  {
                    'branch_head_id': 104,
                    'branch_head_name': 'BM 4',
                    'display_label': 'BM 4 (KZD)',
                    'area_pincode': '673002',
                  },
                ],
              }),
              200,
            );
          }
        }
        return http.Response('{}', 200);
      });

      final vm = CoordinatorUpdateStatusViewModel(
        customer: customer,
        client: mockClient,
        tokenStorage: TokenStorage(),
      );

      await vm.loadBranchManagers();

      expect(vm.branchManagers.length, 2);
      expect(vm.hasMoreManagers, isTrue);
      expect(vm.managerPage, 1);

      await vm.loadNextBranchManagersPage();

      expect(vm.branchManagers.length, 4);
      expect(vm.hasMoreManagers, isFalse);
      expect(vm.managerPage, 2);
      expect(vm.availableManagers.length, 4);
      expect(vm.availableManagers, contains('BM 3 (KZD) - 673001'));
    },
  );

  testWidgets(
    'BranchManagerFieldCard displays Load more... option when hasMore is true and invokes onLoadMore',
    (WidgetTester tester) async {
      bool loadMoreCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BranchManagerFieldCard(
              selectedManager: 'BM 1 (EKM) - 682001',
              onManagerChanged: (_) {},
              managers: const ['BM 1 (EKM) - 682001', 'BM 2 (EKM) - 682002'],
              hasMore: true,
              onLoadMore: () {
                loadMoreCalled = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on card to open popup
      await tester.tap(find.text('BRANCH MANAGER'));
      await tester.pumpAndSettle();

      expect(find.text('Load more...'), findsOneWidget);

      await tester.tap(find.text('Load more...'));
      await tester.pumpAndSettle();

      expect(loadMoreCalled, isTrue);
    },
  );

  testWidgets(
    'BranchManagerFieldCard triggers onLoadMore on scroll when scrolling near the bottom of the popup',
    (WidgetTester tester) async {
      bool loadMoreTriggeredOnScroll = false;
      final managers = List.generate(20, (i) => 'Branch Manager $i');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BranchManagerFieldCard(
              selectedManager: 'Branch Manager 0',
              onManagerChanged: (_) {},
              managers: managers,
              hasMore: true,
              onLoadMore: () {
                loadMoreTriggeredOnScroll = true;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on card to open popup
      await tester.tap(find.text('BRANCH MANAGER'));
      await tester.pumpAndSettle();

      // Scroll the popup down towards the bottom by dragging visible item in popup
      await tester.drag(
        find.text('Branch Manager 0').last,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();

      expect(loadMoreTriggeredOnScroll, isTrue);
    },
  );

  testWidgets(
    'BranchManagerFieldCard dynamically appends new items while popup menu is open when state updates',
    (WidgetTester tester) async {
      List<String> managers = ['BM 1', 'BM 2'];
      bool hasMore = true;
      String selected = 'BM 1';

      late void Function(void Function()) parentSetState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                parentSetState = setState;
                return BranchManagerFieldCard(
                  selectedManager: selected,
                  onManagerChanged: (val) {
                    setState(() => selected = val);
                  },
                  managers: managers,
                  hasMore: hasMore,
                  onLoadMore: () {
                    parentSetState(() {
                      managers = ['BM 1', 'BM 2', 'BM 3 (Page 2)'];
                      hasMore = false;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open the dropdown menu
      await tester.tap(find.text('BRANCH MANAGER'));
      await tester.pumpAndSettle();

      // Page 1 items are shown
      expect(find.text('BM 1'), findsNWidgets(2)); // in card and in menu
      expect(find.text('BM 2'), findsOneWidget);
      expect(find.text('BM 3 (Page 2)'), findsNothing);

      // Now tap Load more... inside the open menu
      await tester.tap(find.text('Load more...'));
      await tester.pump(); // frame for parent setState
      await tester.pumpAndSettle();

      // BM 3 (Page 2) is NOW visible inside the STILL-OPEN popup menu!
      expect(find.text('BM 3 (Page 2)'), findsOneWidget);

      // Tap on BM 3 (Page 2) to select it
      await tester.tap(find.text('BM 3 (Page 2)'));
      await tester.pumpAndSettle();

      // The selection was updated to BM 3 (Page 2)
      expect(selected, 'BM 3 (Page 2)');
    },
  );
}
