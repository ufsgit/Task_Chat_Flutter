import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/today/today_model.dart';
import 'package:task_chat/today/today_view_model.dart';

void main() {
  group('TodayViewModel & BookingModel MVVM Tests', () {
    const mockApiResponse = '''
    {
      "data": [
        {
          "id": 2,
          "name": "Rahul Krishnan",
          "mobile": "+91 94471 22334",
          "address": "House 12, MG Road, Ernakulam",
          "notes": "Double door fitting required",
          "status": "NEW",
          "loginRoleId": 2,
          "loginId": 2,
          "loginName": "Elena Vance",
          "stateId": 1,
          "stateName": "Kerala",
          "districtId": 1,
          "districtName": "Ernakulam Hub",
          "areaId": 1,
          "areaName": "Edapally",
          "documents": ["/uploads/site_plan.pdf"],
          "createdAt": "2026-10-21T10:38:24.000Z",
          "updatedAt": "2026-10-21T10:38:24.000Z"
        },
        {
          "id": 1,
          "name": "Anand Varma",
          "mobile": "+91 98470 11223",
          "address": "Flat 4B, SkyLine Apts, Palarivattom",
          "notes": "Urgent fitting required",
          "status": "COMPLETED",
          "loginRoleId": 2,
          "loginId": 2,
          "loginName": "Elena Vance",
          "stateId": 1,
          "stateName": "Kerala",
          "districtId": 1,
          "districtName": "Ernakulam Hub",
          "areaId": 4,
          "areaName": "Palarivattom",
          "documents": [],
          "createdAt": "2026-10-21T07:14:20.000Z",
          "updatedAt": "2026-10-21T07:14:20.000Z"
        }
      ]
    }
    ''';

    test('BookingModel parses API json response correctly', () {
      final jsonMap = (jsonDecode(mockApiResponse)['data'] as List).first;
      final model = BookingModel.fromJson(jsonMap);

      expect(model.id, 2);
      expect(model.name, 'Rahul Krishnan');
      expect(model.mobile, '+91 94471 22334');
      expect(model.address, 'House 12, MG Road, Ernakulam');
      expect(model.areaName, 'Edapally');
      expect(model.status, 'NEW');
      expect(model.documents.length, 1);

      final chatItem = model.toChatItem();
      expect(chatItem['title'], 'Rahul Krishnan');
      expect(chatItem['avatarLetter'], 'R');
      expect(chatItem['tagText'], 'New');
      expect(chatItem['location'], 'Edapally');
      expect(chatItem['hasVerifiedBadge'], true);
    });

    test('TodayViewModel fetches bookings and filters correctly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(mockApiResponse, 200, headers: {'content-type': 'application/json'});
      });

      final vm = TodayViewModel(client: mockClient);
      await vm.fetchBookings();

      expect(vm.bookings.length, 2);
      expect(vm.filteredChatItems.length, 2);

      // Search filter
      vm.setSearchQuery('Rahul');
      expect(vm.filteredChatItems.length, 1);
      expect(vm.filteredChatItems.first['title'], 'Rahul Krishnan');

      // Clear search
      vm.setSearchQuery('');
      expect(vm.filteredChatItems.length, 2);

      // Status filter
      vm.setStatusFilter('Completed');
      expect(vm.filteredChatItems.length, 1);
      expect(vm.filteredChatItems.first['title'], 'Anand Varma');
    });
  });
}
