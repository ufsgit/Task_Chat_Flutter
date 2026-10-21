import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/login_page/login_view_model.dart';

void main() {
  group('LoginViewModel', () {
    test('validation fails when username or password is empty', () async {
      final vm = LoginViewModel();
      final result = await vm.login(username: '', password: '');
      expect(result.isSuccess, isFalse);
      expect(vm.errorMessage, 'Please enter both username and password');
    });

    test('successful login parses exact API response payload correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/auth/mobile-login');
        return http.Response(
          jsonEncode({
            "user": {
              "id": 4,
              "username": "branch_ekm",
              "roleId": 3,
              "role": "branch_head",
              "userTypeId": 2,
              "userType": "staff",
              "name": "Rajesh Menon",
              "email": "rajesh.menon@steeldoor.com",
              "phone": "+91 98470 12345",
              "stateId": 1,
              "stateName": "Kerala",
              "districtId": 1,
              "districtName": "Ernakulam Hub",
              "districtCode": "dist-ekm",
              "address": null,
              "isActive": 1,
              "lastLoginAt": "2026-10-21T05:30:00.000Z"
            },
            "sessionToken": "eyJpZCI6NCwidXNlcm5hbWUiOiJicmFuY2hfZWttIn0="
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = LoginViewModel(client: mockClient);
      final result = await vm.login(username: 'branch_ekm', password: 'password');

      expect(result.isSuccess, isTrue);
      expect(result.token, 'eyJpZCI6NCwidXNlcm5hbWUiOiJicmFuY2hfZWttIn0=');
      expect(result.user?.name, 'Rajesh Menon');
      expect(result.user?.districtName, 'Ernakulam Hub');
      expect(result.user?.role, 'branch_head');
      expect(result.user?.roleId, 3);
      expect(result.user?.isBranchManager, isTrue);
      expect(result.user?.isCoordinator, isFalse);
      expect(result.isCoordinator, isFalse);
      expect(result.isSuperAdmin, isFalse); // branch_head is Branch Manager, not Coordinator
      expect(vm.isLoading, isFalse);
    });

    test('coordinator login sets isCoordinator to true based on roleId 2', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            "user": {
              "id": 1,
              "username": "coordinator_main",
              "roleId": 2,
              "role": "coordinator",
              "name": "Central Coordinator",
            },
            "sessionToken": "coordinator_token_123"
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = LoginViewModel(client: mockClient);
      final result = await vm.login(username: 'coordinator_main', password: 'password');

      expect(result.isSuccess, isTrue);
      expect(result.user?.roleId, 2);
      expect(result.user?.isCoordinator, isTrue);
      expect(result.user?.isBranchManager, isFalse);
      expect(result.isCoordinator, isTrue);
      expect(result.isSuperAdmin, isTrue); // roleId 2 is Coordinator
    });

    test('failed login sets error message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'Invalid credentials or user is not authorized for mobile login (role 2 or 3).'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final vm = LoginViewModel(client: mockClient);
      final result = await vm.login(username: 'test', password: 'wrong');

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, 'Invalid login');
    });
  });
}
