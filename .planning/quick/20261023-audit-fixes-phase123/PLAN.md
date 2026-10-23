# Quick Task: Fix Phase 1, Phase 2, and Phase 3 Findings from Audit Report

## Objectives
1. **Phase 1 (Critical & Build/Auth/Data Integrity)**:
   - Add `android.permission.INTERNET` to `android/app/src/main/AndroidManifest.xml`.
   - Remove 300ms timeout on `TokenStorage.getToken()` in `today_view_model.dart` and `customer_details_view_model.dart` (increase to 5s).
   - Wire backend API persistence (`PUT /api/bookings/:id`) on status updates in `CustomerDetailsView._openUpdateStatusPage`.
2. **Phase 2 (Stability & Leak Fixes)**:
   - Implement `dispose()` on `TodayViewModel`, `CustomerDetailsViewModel`, `AddBookingViewModel`, and `AreaViewModel` to close `_client`.
   - Wrap dialog controllers in `try-finally` blocks to call `.dispose()` in `customer_details_view.dart` and `add_booking_view.dart`.
   - Clear `todayChatItems` during `SettingsViewModel.logout()` to prevent cross-user data leakage.
   - Trigger `fetchBookings()` for Coordinator users in `BottomNavigator` so coordinator view has populated data.
3. **Phase 3 (Performance & Optimization)**:
   - Add a 300ms debounce timer to `AreaViewModel.setSearch()`.
   - Only call `fetchBookings()` on returning from customer details if `updatedStatus != null`.
   - Memoize `coordinatorChatItems` in `cordinator_data.dart` to prevent GC churn during scroll.
