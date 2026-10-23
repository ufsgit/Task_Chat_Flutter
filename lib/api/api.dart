/// Central API configuration.
abstract final class ApiConfig {
  static const String baseUrl = 'https://7qh4z02n-5000.inc1.devtunnels.ms';
  static const String mobileLogin = '$baseUrl/api/auth/mobile-login';
  static const String bookings = '$baseUrl/api/bookings';
  static const String area_listing = '$baseUrl/api/dropdowns';
  static const String coordinator_area_listing = '$baseUrl/api/dropdowns/areas';
  static const String statusUpdate = '$baseUrl/api/status';
  static const String district_listing = '$baseUrl/api/dropdowns/districts';
  static const String branch_head_listing = '$baseUrl/api/users?role=branch_head';
  static const String branch_manager_listing = '$baseUrl/api/users?role=branch_head';
  static const String users = '$baseUrl/api/users';
}
