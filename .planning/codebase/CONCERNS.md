# Technical Concerns & Areas for Improvement

## 1. Test Regressions
- **Issue**: 3 widget tests currently fail in `flutter test`:
  - `test/customer_details_structure_test.dart` (2 failures: section order assertion and missing "Add notes here..." placeholder).
  - `test/metric_stat_card_test.dart` (1 failure: mismatch on percentage text "64.5%").
- **Impact**: Continuous Integration / pre-commit validation fails.
- **Action**: Align widget text/layout in `ContactActionsCard` and `MetricStatCard` with test expectations or update tests to reflect current UX designs.


## 2. In-Memory State Synchronization
- **Issue**: In [`lib/today/today_view_model.dart`](file:///c:/task_chat/lib/today/today_view_model.dart), a top-level mutable global list `final List<Map<String, dynamic>> todayChatItems = [];` is maintained for backward compatibility with status updates.
- **Impact**: Global mutable state can introduce race conditions, state drift across hot reloads, or multiple conflicting sources of truth between ViewModels.
- **Action**: Encapsulate booking and chat state within a single repository or singleton service injected into both `TodayViewModel` and `UpdateStatusViewModel`.

## 3. Error & Offline Resiliency
- **Issue**: Network exceptions in `TodayViewModel` and `CustomerDetailsViewModel` catch general exceptions and surface raw strings to the UI rather than localized or user-friendly error banners.
- **Impact**: Suboptimal UX when operating under poor network conditions.
- **Action**: Introduce standardized network state representation (`AsyncValue` or `Result<T>`) with retry mechanisms and offline caching.
