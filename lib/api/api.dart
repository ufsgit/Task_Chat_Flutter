/// Central API configuration.
abstract final class ApiConfig {
  //static const String baseUrl = 'https://7qh4z02n-5000.inc1.devtunnels.ms';

  static const String baseUrl = 'https://steeldoorapi.ufstech.co.in';
  //static const String baseUrl = 'https://fg34kvb9-5000.inc1.devtunnels.ms';
  static const String mobileLogin = '$baseUrl/api/auth/mobile-login';
  static const String bookings = '$baseUrl/api/bookings';
  static const String area_listing = '$baseUrl/api/dropdowns/areas';
  static const String coordinator_area_listing = area_listing;
  static const String statusUpdate = '$baseUrl/api/status';
  static const String status_chips = statusUpdate;
  static const String district_listing = '$baseUrl/api/dropdowns/districts';
  static const String branch_head_listing =
      '$baseUrl/api/users/get_branch_heads_for_status_update';
  static const String branch_manager_listing = branch_head_listing;
  static const String users = '$baseUrl/api/users';
  static const String uploads = '$baseUrl/api/uploads/multiple';
  static const String multipleUploads = uploads;
  static const String dashboard = '$baseUrl/api/mobile-dashboard/metrics';
  static const String history_list = '$baseUrl/api/booking-history';
  static const String history_list_test =
      '$baseUrl/api/booking-history?search=n&fromDate=2026-11-25&toDate=2026-11-25&page=1&limit=20';
  static const String report_graph = '$baseUrl/api/reports/bookings';
  static const String report_graph_bybookingid =
      '$baseUrl/api/booking-history/{bookingId}';
  static const String notificationDeviceToken =
      '$baseUrl/api/notifications/device-token';
  static const String notificationUnregister =
      '$baseUrl/api/notifications/unregister';

  static String reportGraphByBookingId(dynamic bookingId) =>
      report_graph_bybookingid.replaceAll('{bookingId}', bookingId.toString());

  static String historyListFiltered({
    String? search,
    String? fromDate,
    String? toDate,
    int page = 1,
    int limit = 20,
  }) {
    final params = <String, String>{
      if (search != null && search.isNotEmpty) 'search': search,
      if (fromDate != null && fromDate.isNotEmpty) 'fromDate': fromDate,
      if (toDate != null && toDate.isNotEmpty) 'toDate': toDate,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    return Uri.parse(history_list).replace(queryParameters: params).toString();
  }

  static const String Checkvalid = '$baseUrl/api/auth/me';
  static const String checkValid = Checkvalid;
  static const String brochure = '$baseUrl/api/brochures';
}
