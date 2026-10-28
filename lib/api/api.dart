/// Central API configuration.
abstract final class ApiConfig {
  static const String baseUrl = 'https://fg34kvb9-5000.inc1.devtunnels.ms';
  static const String mobileLogin = '$baseUrl/api/auth/mobile-login';
  static const String bookings = '$baseUrl/api/bookings';
  static const String area_listing = '$baseUrl/api/dropdowns';
  static const String coordinator_area_listing = '$baseUrl/api/dropdowns/areas';
  static const String statusUpdate = '$baseUrl/api/status';
  static const String status_chips = '$baseUrl/api/status';
  static const String district_listing = '$baseUrl/api/dropdowns/districts';
  static const String branch_head_listing =
      '$baseUrl/api/users?role=branch_head';
  static const String branch_manager_listing = branch_head_listing;
  static const String users = '$baseUrl/api/users';
  static const String uploads = '$baseUrl/api/uploads/multiple';
  static const String multipleUploads = uploads;
  static const String dashboard = '$baseUrl/api/mobile-dashboard/metrics';
}
