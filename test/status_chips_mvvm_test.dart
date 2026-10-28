import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/api/api.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/login_page/token_storage.dart';
import 'package:task_chat/update_status/branch_manager/branch_manager_update_status_view_model.dart';
import 'package:task_chat/update_status/coordinators/coordinator_update_status_view_model.dart';
import 'package:task_chat/update_status/models/status_chip_model.dart';
import 'package:task_chat/update_status/services/status_chips_service.dart';
import 'package:task_chat/update_status/widgets/status_chips_skeleton.dart';
import 'package:task_chat/update_status/widgets/status_selector_chips.dart';

void main() {
  setUp(() {
    TokenStorage.useMemoryOnly = true;
  });

  tearDown(() {
    TokenStorage.useMemoryOnly = false;
  });

  const mockStatusApiResponse = {
    "success": true,
    "count": 4,
    "data": [
      {
        "id": 1,
        "code": "NEW",
        "label": "New",
        "colorCode": "#3b82f6",
        "sortOrder": 1,
        "isActive": 1
      },
      {
        "id": 2,
        "code": "Scheduled",
        "label": "Scheduled",
        "colorCode": "#7c3aed",
        "sortOrder": 2,
        "isActive": 1
      },
      {
        "id": 3,
        "code": "Completed",
        "label": "Completed",
        "colorCode": "#10b981",
        "sortOrder": 3,
        "isActive": 1
      },
      {
        "id": 4,
        "code": "Cancelled",
        "label": "Cancelled",
        "colorCode": "#ef4444",
        "sortOrder": 4,
        "isActive": 1
      }
    ]
  };

  test('StatusChipModel parses correctly from backend JSON', () {
    final chip = StatusChipModel.fromJson({
      "id": 2,
      "code": "Scheduled",
      "label": "Scheduled",
      "colorCode": "#7c3aed",
      "sortOrder": 2,
      "isActive": 1,
    });

    expect(chip.id, 2);
    expect(chip.code, "Scheduled");
    expect(chip.label, "Scheduled");
    expect(chip.colorCode, "#7c3aed");
    expect(chip.sortOrder, 2);
    expect(chip.isActive, isTrue);
  });

  test('StatusChipsService fetches and sorts active status chips from ApiConfig.status_chips', () async {
    final mockClient = MockClient((request) async {
      expect(request.url.toString(), ApiConfig.status_chips);
      return http.Response(
        jsonEncode(mockStatusApiResponse),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = StatusChipsService(client: mockClient);
    final chips = await service.fetchStatusChips();

    expect(chips.length, 4);
    expect(chips.map((c) => c.label).toList(), ['New', 'Scheduled', 'Completed', 'Cancelled']);
  });

  test('BranchManagerUpdateStatusViewModel hides Completed when new and removes New after scheduled', () async {
    final mockClient = MockClient((request) async {
      if (request.url.toString() == ApiConfig.status_chips) {
        return http.Response(
          jsonEncode(mockStatusApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    // 1. When it's New:
    const newCustomer = CustomerDetailsData(
      id: '1',
      name: 'New Customer',
      inquiry: 'Test Inquiry',
      status: 'New',
      phoneNumber: '1234567890',
      addressLine1: 'Address 1',
      addressLine2: 'Address 2',
      notes: '',
      hasBeenScheduled: false,
    );

    final newVm = BranchManagerUpdateStatusViewModel(
      customer: newCustomer,
      client: mockClient,
    );

    await newVm.loadStatusChips();

    // Completed is NOT shown when New
    expect(newVm.statusChips.map((c) => c.label).toList(), ['New', 'Scheduled', 'Cancelled']);
    expect(newVm.availableOptions.contains('Completed'), isFalse);
    expect(newVm.availableOptions.contains('New'), isTrue);

    // 2. After scheduled:
    const scheduledCustomer = CustomerDetailsData(
      id: '2',
      name: 'Scheduled Customer',
      inquiry: 'Test Inquiry',
      status: 'Scheduled',
      phoneNumber: '1234567890',
      addressLine1: 'Address 1',
      addressLine2: 'Address 2',
      notes: '',
      hasBeenScheduled: true,
    );

    final scheduledVm = BranchManagerUpdateStatusViewModel(
      customer: scheduledCustomer,
      client: mockClient,
    );

    await scheduledVm.loadStatusChips();

    // New is REMOVED, Completed is SHOWN after scheduled
    expect(scheduledVm.statusChips.map((c) => c.label).toList(), ['Scheduled', 'Completed', 'Cancelled']);
    expect(scheduledVm.availableOptions.contains('New'), isFalse);
    expect(scheduledVm.availableOptions.contains('Completed'), isTrue);
  });

  test('CoordinatorUpdateStatusViewModel hides Completed when new and removes New after scheduled', () async {
    final mockClient = MockClient((request) async {
      if (request.url.toString() == ApiConfig.status_chips) {
        return http.Response(
          jsonEncode(mockStatusApiResponse),
          200,
          headers: {'content-type': 'application/json'},
        );
      }
      return http.Response('Not Found', 404);
    });

    // 1. When it's New:
    const newCustomer = CustomerDetailsData(
      id: '1',
      name: 'New Customer',
      inquiry: 'Test Inquiry',
      status: 'New',
      phoneNumber: '1234567890',
      addressLine1: 'Address 1',
      addressLine2: 'Address 2',
      notes: '',
      hasBeenScheduled: false,
    );

    final newVm = CoordinatorUpdateStatusViewModel(
      customer: newCustomer,
      client: mockClient,
    );

    await newVm.loadStatusChips();

    // Completed is NOT shown when New
    expect(newVm.statusChips.map((c) => c.label).toList(), ['New', 'Scheduled', 'Cancelled']);
    expect(newVm.availableOptions.contains('Completed'), isFalse);

    // 2. After scheduled:
    const scheduledCustomer = CustomerDetailsData(
      id: '2',
      name: 'Scheduled Customer',
      inquiry: 'Test Inquiry',
      status: 'Scheduled',
      phoneNumber: '1234567890',
      addressLine1: 'Address 1',
      addressLine2: 'Address 2',
      notes: '',
      hasBeenScheduled: true,
    );

    final scheduledVm = CoordinatorUpdateStatusViewModel(
      customer: scheduledCustomer,
      client: mockClient,
    );

    await scheduledVm.loadStatusChips();

    // New is REMOVED, Completed is SHOWN after scheduled
    expect(scheduledVm.statusChips.map((c) => c.label).toList(), ['Scheduled', 'Completed', 'Cancelled']);
    expect(scheduledVm.availableOptions.contains('New'), isFalse);
    expect(scheduledVm.availableOptions.contains('Completed'), isTrue);
  });

  testWidgets('StatusSelectorChips displays StatusChipsSkeleton when isLoading is true', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusSelectorChips(
            selectedStatus: 'Scheduled',
            isLoading: true,
            onStatusSelected: (_) {},
          ),
        ),
      ),
    );

    expect(find.byType(StatusChipsSkeleton), findsOneWidget);
  });

  testWidgets('StatusSelectorChips renders backend chips and allows selection', (tester) async {
    String selected = 'Scheduled';

    final chips = [
      const StatusChipModel(id: 1, code: 'NEW', label: 'New', colorCode: '#3b82f6', sortOrder: 1, isActive: true),
      const StatusChipModel(id: 2, code: 'Scheduled', label: 'Scheduled', colorCode: '#7c3aed', sortOrder: 2, isActive: true),
      const StatusChipModel(id: 3, code: 'Completed', label: 'Completed', colorCode: '#10b981', sortOrder: 3, isActive: true),
      const StatusChipModel(id: 4, code: 'Cancelled', label: 'Cancelled', colorCode: '#ef4444', sortOrder: 4, isActive: true),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: StatusSelectorChips(
                selectedStatus: selected,
                chips: chips,
                onStatusSelected: (newVal) {
                  setState(() => selected = newVal);
                },
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('New'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);

    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(selected, 'Completed');
  });

  test('StatusChipModel.fromJson parses statusColorCode field correctly', () {
    final json = {
      'id': 2,
      'code': 'Scheduled',
      'label': 'Scheduled',
      'statusColorCode': '#7c3aed',
      'sortOrder': 2,
      'isActive': 1,
    };
    final model = StatusChipModel.fromJson(json);
    expect(model.colorCode, '#7c3aed');
  });

  testWidgets('StatusSelectorChips uses colorCode / statusColorCode from API', (tester) async {
    const chips = [
      StatusChipModel(id: 1, code: 'New', label: 'New', colorCode: '#3b82f6', sortOrder: 1, isActive: true),
      StatusChipModel(id: 2, code: 'Scheduled', label: 'Scheduled', colorCode: '#7c3aed', sortOrder: 2, isActive: true),
    ];

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusSelectorChips(
            selectedStatus: 'Scheduled',
            chips: chips,
            onStatusSelected: _noop,
          ),
        ),
      ),
    );

    // Scheduled is selected -> should have background color 0xFF7C3AED
    final scheduledContainer = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text('Scheduled'),
        matching: find.byType(AnimatedContainer),
      ).first,
    );
    final scheduledDeco = scheduledContainer.decoration as BoxDecoration;
    expect(scheduledDeco.color, const Color(0xFF7C3AED));

    // New is unselected -> text should be colored with 0xFF3B82F6
    final newText = tester.widget<Text>(find.text('New'));
    expect(newText.style?.color, const Color(0xFF3B82F6));
  });

  testWidgets('StatusSelectorChips displays label for the name of status', (tester) async {
    const chips = [
      StatusChipModel(id: 1, code: 'NEW_CODE', label: 'New', colorCode: '#3b82f6', sortOrder: 1, isActive: true),
      StatusChipModel(id: 2, code: 'SCHEDULED_CODE', label: 'Scheduled', colorCode: '#7c3aed', sortOrder: 2, isActive: true),
      StatusChipModel(id: 3, code: 'COMPLETED_CODE', label: 'Completed', colorCode: '#10b981', sortOrder: 3, isActive: true),
      StatusChipModel(id: 4, code: 'CANCELLED_CODE', label: 'Cancelled', colorCode: '#ef4444', sortOrder: 4, isActive: true),
    ];

    String? tappedStatus;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatusSelectorChips(
            selectedStatus: 'SCHEDULED_CODE', // selected by code
            chips: chips,
            onStatusSelected: (val) => tappedStatus = val,
          ),
        ),
      ),
    );

    // Verifies the labels are displayed, NOT the codes
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(find.text('SCHEDULED_CODE'), findsNothing);

    // Tapping passes the label
    await tester.tap(find.text('Completed'));
    expect(tappedStatus, 'Completed');
  });
}

void _noop(String val) {}

