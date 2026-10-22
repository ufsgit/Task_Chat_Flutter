# Testing Strategy & Status

## Test Framework
- **Test Runner**: `flutter_test` (built into Flutter SDK)
- **Command**:
  ```bash
  flutter test
  ```

## Structure & Categories
The project features 18 test files categorized into:
1. **ViewModel Unit Tests**:
   - `test/login_view_model_test.dart`: Validates authentication state transitions, credential validation, failure error messages, and network timeout handling.
   - `test/today_view_model_test.dart`: Validates booking filtering by status (All, Unread, Pending), query searching, and token headers.
   - `test/customer_details_view_model_test.dart`: Validates contact edits, deletion workflows, and status changes.
   - `test/add_booking_view_model_test.dart` & `test/area_view_model_test.dart`: Validates booking submission and area selection dropdown state.
2. **Widget & Screen Integration Tests**:
   - `test/splash_screen_test.dart`: Validates timer-based navigation and brand rendering.
   - `test/settings_page_test.dart`: Validates theme toggle, dark mode switching, and logout confirmation dialogs.
   - `test/notification_page_test.dart`: Validates notification list items, filtering chips, and section headers.
   - `test/update_status_page_test.dart`: Validates dynamic visibility of schedule picker card based on status selection.
   - `test/widget_test.dart`: Smoke test ensuring `FitmateApp` builds without crashing.

## Mocking Strategy
- Hermetic tests mock dependencies using lightweight custom implementations or subclassed `http.Client` instances without depending on heavy third-party mock generators.
- `TokenStorage.useMemoryOnly = true` is used across unit tests to bypass platform secure storage channels.

## Current Test Suite Status (October 2026)
- **Passing**: 49 tests
- **Failing**: 3 tests
  - `test/customer_details_structure_test.dart`:
    - "ContactActionsCard orders sections: Address first, Notes second, Contact last"
    - "Notes box in ContactActionsCard is clickable and typable" (Text "Add notes here..." not found)
  - `test/metric_stat_card_test.dart`:
    - "MetricStatCard renders title beside icon and no progress bar for completed" (Expected text "64.5%" not found)
