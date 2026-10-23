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
import 'package:task_chat/today/today_view_model.dart';
import 'package:task_chat/update_status/branch_manager/branch_manager_update_status_logic.dart';
import 'package:task_chat/update_status/branch_manager/branch_manager_update_status_view.dart';
import 'package:task_chat/update_status/branch_manager/branch_manager_update_status_view_model.dart';
import 'package:task_chat/update_status/coordinators/coordinator_update_status_view.dart';
import 'package:task_chat/update_status/coordinators/coordinator_update_status_view_model.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TokenStorage.useMemoryOnly = true;
    todayChatItems.clear();
  });

  tearDown(() {
    TokenStorage.useMemoryOnly = false;
  });

  test('StatusUpdateRequest serialization and deserialization matches API example', () {
    const jsonMap = {
      'clientId': 1,
      'clientName': 'Abhijith',
      'status': 'Scheduled',
      'scheduleDate': '10/24/2024',
      'notes': 'Client confirmed fitting for tomorrow afternoon.',
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
  });

  test('UpdateStatusVisibility hides schedule when cancelled', () {
    const scheduledVis = UpdateStatusVisibility('Scheduled');
    expect(scheduledVis.showSchedule, isTrue);

    const completedVis = UpdateStatusVisibility('Completed');
    expect(completedVis.showSchedule, isTrue);

    const cancelledVis = UpdateStatusVisibility('Cancelled');
    expect(cancelledVis.showSchedule, isFalse);
  });

  testWidgets('UpdateStatusPage hides Schedule card when Cancelled is selected', (
    WidgetTester tester,
  ) async {
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

    await tester.pumpWidget(
      const MaterialApp(
        home: UpdateStatusPage(customer: customer),
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
  });

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
      status: 'New',
      phoneNumber: '+91 9876543210',
      addressLine1: 'Kochi',
      addressLine2: 'Kerala',
      notes: '',
      hasBeenScheduled: false,
    );

    http.Request? capturedRequest;
    final mockClient = MockClient((request) async {
      capturedRequest = request;
      if (request.url.toString() == ApiConfig.statusUpdate) {
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

    final parsedBody = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
    expect(parsedBody['clientId'], 1);
    expect(parsedBody['clientName'], 'Abhijith');
    expect(parsedBody['status'], 'Scheduled');
    expect(parsedBody['notes'], 'Fitting confirmed');
    expect(parsedBody['createdBy'], 4);
    expect(parsedBody['createdByName'], 'Rajesh Menon');

    // Verify todayChatItems updated
    expect(todayChatItems.first['tagText'], 'Scheduled');
  });

  testWidgets('CoordinatorUpdateStatusPage posts to ApiConfig.statusUpdate on Save', (
    WidgetTester tester,
  ) async {
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
      capturedRequest = request;
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

    final parsedBody = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
    expect(parsedBody['clientId'], 5);
    expect(parsedBody['clientName'], 'Client Five');
    expect(parsedBody['createdBy'], 10);
    expect(parsedBody['createdByName'], 'Super Coordinator');
  });

  test('BranchManagerUpdateStatusViewModel and CoordinatorUpdateStatusViewModel initialize and update state', () {
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

    final bmViewModel = BranchManagerUpdateStatusViewModel(customer: customer);
    expect(bmViewModel.selectedStatus, 'Scheduled');
    expect(bmViewModel.showSchedule, isTrue);
    expect(bmViewModel.availableOptions, equals(['Scheduled', 'Cancelled']));

    bmViewModel.setStatus('Cancelled');
    expect(bmViewModel.selectedStatus, 'Cancelled');
    expect(bmViewModel.showSchedule, isFalse);

    bmViewModel.setScheduleDate('11/01/2026');
    expect(bmViewModel.scheduleDate, '11/01/2026');
    bmViewModel.dispose();

    final coordViewModel = CoordinatorUpdateStatusViewModel(customer: customer);
    expect(coordViewModel.selectedStatus, 'Scheduled');
    expect(coordViewModel.showSchedule, isTrue);
    expect(coordViewModel.availableOptions, equals(['Scheduled', 'Cancelled']));

    coordViewModel.setBranchManager('Ramesh Kumar');
    expect(coordViewModel.selectedBranchManager, 'Ramesh Kumar');
    coordViewModel.dispose();
  });
}
