# Quick Task: Implement Dashboard API Integration with MVVM Architecture

## Objectives
1. **Model Layer (`lib/dashboard/models/dashboard_model.dart`)**:
   - Create `DashboardPeriod` enum mapping:
     - `Current Month` -> `this_month`
     - `Last 30 Days` -> `last_30_days`
     - `All Time` -> `all`
   - Create `DashboardModel` with fields for `newBooking`, `pending`, `completed`, `scheduled`, `total`.
   - Implement resilient `DashboardModel.fromJson` supporting multiple API response structures (snake_case, camelCase, nested under data/counts/items, and status lists).
   - Provide helper `toMetricCards(DashboardPeriod period)` generating the 4 styled `MetricCardData` objects.

2. **Service Layer (`lib/dashboard/services/dashboard_service.dart`)**:
   - Implement `DashboardService` calling `ApiConfig.dashboard` with query parameter `period={this_month|last_30_days|all}`.
   - Include `Authorization: Bearer <token>` from `TokenStorage` and `Accept: application/json`.
   - Support dependency injection of `http.Client` and `TokenStorage` for robust unit testing.

3. **ViewModel Layer (`lib/dashboard/dashboard_view_model.dart`)**:
   - Implement `DashboardViewModel` extending `ChangeNotifier`.
   - Manage state: `isLoading`, `errorMessage`, `selectedPeriod`, `dashboardData`.
   - Provide `fetchDashboard({DashboardPeriod? period})`, `selectFilter(String filterLabel)`, and `retry()`.
   - Handle resource disposal properly.

4. **View Layer (`lib/dashboard/dashboard_page.dart` & `lib/dashboard/widgets/dashboard_skeleton.dart`)**:
   - Refactor `DashboardPage` to consume `DashboardViewModel` via `AnimatedBuilder`.
   - Connect `DashboardTimeFilterBar` to `_viewModel.selectFilter`.
   - Render shimmer/skeleton loading cards during `isLoading`.
   - Render error message with retry button on network failure.
   - Support pull-to-refresh (`RefreshIndicator`).
   - Retain exact UI styling, typography (`Helvetica Neue`), colors, dark/light theme support, and scroll physics.

5. **Verification**:
   - Write unit and widget tests in `test/dashboard_mvvm_test.dart` verifying period query parameter mapping, JSON serialization, state management, and UI rendering.
   - Verify with `dart analyze` and `flutter test`.
