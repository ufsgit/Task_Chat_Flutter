---
status: complete
date: 2026-10-27
slug: 20261027-dashboard-api-mvvm
description: "Migrate Dashboard to MVVM architecture and integrate with GET /api/bookings/dashboard"
---

# Summary: Dashboard API Integration with MVVM Architecture

## Completed Changes

### 1. Model Layer (`lib/dashboard/models/dashboard_model.dart`)
- **`DashboardPeriod`**: Enum for the time filters:
  - `currentMonth` (`'Current Month'`) -> `period=this_month`
  - `last30Days` (`'Last 30 Days'`) -> `period=last_30_days`
  - `allTime` (`'All Time'`) -> `period=all`
- **`DashboardModel`**:
  - Strongly typed model parsing `newBooking`, `pending`, `completed`, `scheduled`, and `total`.
  - Resilient JSON parser supporting camelCase, snake_case, array of status items, and string numbers.
  - Card conversion helpers generating styled `MetricCardData` with the exact theme colors and icons.

### 2. Service Layer (`lib/dashboard/services/dashboard_service.dart`)
- **`DashboardService`**: Calls `GET /api/bookings/dashboard?period=...` with authentication token from `TokenStorage` and `Accept: application/json` header.
- Supports dependency injection of `http.Client` and `TokenStorage` for testability.

### 3. ViewModel Layer (`lib/dashboard/dashboard_view_model.dart`)
- **`DashboardViewModel`**: `ChangeNotifier` managing:
  - State: `isLoading`, `errorMessage`, `selectedPeriod`, `dashboardData`.
  - Filter selection: `selectFilter(String label)` updating period and fetching metrics.
  - Lifecycle: safe disposal of internal `http.Client`.

### 4. View Layer (`lib/dashboard/dashboard_page.dart` & `widgets/dashboard_skeleton.dart`)
- **`DashboardPage`**:
  - Replaced hardcoded static values with `AnimatedBuilder` observing `DashboardViewModel`.
  - Connected `DashboardTimeFilterBar` to `_viewModel.selectFilter`.
  - Added `DashboardMetricsSkeletonGrid` for smooth shimmer-like loading states.
  - Added error display with retry button.
  - Wrapped in `RefreshIndicator` for pull-to-refresh.
  - Uses `BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())`.

### 5. Automated Tests (`test/dashboard_mvvm_test.dart`)
- 10 unit and widget tests covering period query parameter mapping, JSON serialization, service calls, ViewModel state transitions, and widget rendering.

## Verification
- `dart analyze lib/dashboard test/dashboard_mvvm_test.dart`: 0 issues found.
- `flutter test test/dashboard_mvvm_test.dart`: 10/10 tests passed.
