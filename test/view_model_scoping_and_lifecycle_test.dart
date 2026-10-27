import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:task_chat/Coordinator/coordinator_view_model.dart';
import 'package:task_chat/customer_details/customer_details_model.dart';
import 'package:task_chat/customer_details/customer_details_view_model.dart';
import 'package:task_chat/login_page/login_view_model.dart';
import 'package:task_chat/new_booking/add_booking_view_model.dart';
import 'package:task_chat/new_booking/area_view_model.dart';
import 'package:task_chat/new_booking/district_view_model.dart';
import 'package:task_chat/today/today_view_model.dart';

class ClosableTrackableClient extends http.BaseClient {
  final http.Client _inner;
  bool isClosed = false;

  ClosableTrackableClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (isClosed) {
      throw http.ClientException('Cannot use a closed client');
    }
    return _inner.send(request);
  }

  @override
  void close() {
    isClosed = true;
    _inner.close();
  }
}

void main() {
  group('ViewModel Data Scoping Tests', () {
    test('CoordinatorViewModel and TodayViewModel do not overwrite each other data', () async {
      final todayApiResponse = jsonEncode({
        'status': 'success',
        'data': [
          {
            'id': 1,
            'name': 'Today Customer 1',
            'mobile': '1111111111',
            'address': 'Kochi',
            'status': 'NEW',
            'notes': 'Today inquiry',
            'createdAt': '2026-10-27T10:00:00.000Z',
          },
        ],
      });

      final coordinatorApiResponse = jsonEncode({
        'status': 'success',
        'data': [
          {
            'id': 2,
            'name': 'Coordinator Customer 2',
            'mobile': '2222222222',
            'address': 'Calicut',
            'status': 'SCHEDULED',
            'notes': 'Coordinator inquiry',
            'branchHeadName': 'Sarah Jenkins',
            'createdAt': '2026-10-27T10:00:00.000Z',
          },
        ],
      });

      final mockClient = MockClient((request) async {
        if (request.url.queryParameters['role'] == 'coordinator' ||
            request.url.path.contains('coordinator')) {
          return http.Response(coordinatorApiResponse, 200);
        }
        return http.Response(todayApiResponse, 200);
      });

      final todayVm = TodayViewModel(client: mockClient);
      await todayVm.fetchBookings();

      expect(todayVm.filteredChatItems.length, 1);
      expect(todayVm.filteredChatItems.first['title'], 'Today Customer 1');

      // Now create CoordinatorViewModel with its own items
      final coordinatorMockClient = MockClient((request) async {
        return http.Response(coordinatorApiResponse, 200);
      });
      final coordVm = CoordinatorViewModel(client: coordinatorMockClient);
      await coordVm.fetchBookings();

      // Coordinator has its own scoped item
      expect(coordVm.filteredChatItems.length, 1);
      expect(coordVm.filteredChatItems.first['title'], 'Coordinator Customer 2');

      // Today ViewModel still has its own scoped item! It was not erased!
      expect(todayVm.filteredChatItems.length, 1);
      expect(todayVm.filteredChatItems.first['title'], 'Today Customer 1');

      // Updating status on coordinator does not affect today
      coordVm.updateStatus('Coordinator Customer 2', 'Completed');
      expect(coordVm.filteredChatItems.first['tagText'], 'Completed');
      expect(todayVm.filteredChatItems.first['tagText'], 'New');

      todayVm.dispose();
      coordVm.dispose();
    });
  });

  group('ViewModel External Client Lifecycle Tests', () {
    test('External client is NOT closed when ViewModels are disposed', () async {
      final mockInner = MockClient((request) async {
        return http.Response('{"status":"success","data":[]}', 200);
      });
      final sharedClient = ClosableTrackableClient(mockInner);

      // 1. LoginViewModel
      final loginVm = LoginViewModel(client: sharedClient);
      loginVm.dispose();
      expect(sharedClient.isClosed, isFalse, reason: 'LoginViewModel must not close external client');

      // 2. TodayViewModel
      final todayVm = TodayViewModel(client: sharedClient);
      todayVm.dispose();
      expect(sharedClient.isClosed, isFalse, reason: 'TodayViewModel must not close external client');

      // 3. CoordinatorViewModel
      final coordVm = CoordinatorViewModel(client: sharedClient);
      coordVm.dispose();
      expect(sharedClient.isClosed, isFalse, reason: 'CoordinatorViewModel must not close external client');

      // 4. CustomerDetailsViewModel
      final customerData = CustomerDetailsModel(
        id: '1',
        name: 'Test',
        inquiry: 'Test',
        status: 'New',
        phoneNumber: '1234567890',
        addressLine1: 'Test Address',
        addressLine2: 'Test City',
        notes: '',
        documents: [],
      );
      final customerVm = CustomerDetailsViewModel(customer: customerData, client: sharedClient);
      customerVm.dispose();
      expect(sharedClient.isClosed, isFalse, reason: 'CustomerDetailsViewModel must not close external client');

      // 5. AreaViewModel
      final areaVm = AreaViewModel(client: sharedClient);
      areaVm.dispose();
      expect(sharedClient.isClosed, isFalse, reason: 'AreaViewModel must not close external client');

      // 6. DistrictViewModel
      final districtVm = DistrictViewModel(client: sharedClient);
      districtVm.dispose();
      expect(sharedClient.isClosed, isFalse, reason: 'DistrictViewModel must not close external client');

      // 7. AddBookingViewModel
      final addBookingVm = AddBookingViewModel(client: sharedClient);
      addBookingVm.dispose();
      expect(sharedClient.isClosed, isFalse, reason: 'AddBookingViewModel must not close external client');

      // Ensure subsequent request still succeeds and doesn't throw "Cannot use a closed client"
      final res = await sharedClient.get(Uri.parse('https://example.com'));
      expect(res.statusCode, 200);

      // Close external client explicitly
      sharedClient.close();
      expect(sharedClient.isClosed, isTrue);
    });
  });
}
