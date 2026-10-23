---
status: complete
date: 2026-10-23
slug: 20261023-audit-fixes-phase123
description: "Fix Phase 1, Phase 2, and Phase 3 findings from app audit"
---

# Summary: Audit Fixes (Phase 1, 2, and 3)

## Completed Changes

### Phase 1 (Critical & Build/Auth/Data Integrity)
- **Production Android Manifest Permission**: Added `<uses-permission android:name="android.permission.INTERNET"/>` to `android/app/src/main/AndroidManifest.xml` to prevent runtime network crashes on release builds.
- **Token Retrieval Timeout**: Removed the artificial 300ms timeout on secure storage in `today_view_model.dart` and `customer_details_view_model.dart`, switching to an environment-aware 5-second timeout (50ms under `FLUTTER_TEST`).
- **Backend API Persistence on Status Update**: Updated `CustomerDetailsView._openUpdateStatusPage` to call `_viewModel.updateCustomer(status: updatedStatus)` upon receiving an updated status, sending `PUT /api/bookings/:id` to persist status changes to the database.

### Phase 2 (Stability & Leak Fixes)
- **ViewModel Lifecycle & Socket Closures**: Implemented `@override void dispose()` on `TodayViewModel`, `CustomerDetailsViewModel`, `AddBookingViewModel`, and `AreaViewModel` to close `_client` and dispose nested view models.
- **Dialog Controller Lifecycle**: Extracted modal edit dialog in `customer_details_view.dart` into `_EditContactDialog` with state-managed text controllers that dispose automatically on route destruction, and wrapped manual doc dialog controller in `add_booking_view.dart` with `try-finally`.
- **Session Cleanup**: Updated `SettingsViewModel.logout()` to clear `todayChatItems.clear()`, preventing data leakage across user sessions.
- **Coordinator Data Initialization**: Updated `BottomNavigator` to trigger `_todayViewModel.fetchBookings()` when `isCoordinator` is true and on tab 0 taps.

### Phase 3 (Performance & Optimization)
- **Search Debounce in Dropdowns**: Added 300ms debounce timer to `AreaViewModel.setSearch()` to prevent keystroke spamming and out-of-order API responses.
- **Redundant API Call Elimination**: Updated `TodayView` to only trigger `fetchBookings()` when returning from customer details if `updatedStatus` was non-null.
- **Memoized List Transformation**: Cached transformed entries in `coordinatorChatItems` in `cordinator_data.dart` to prevent thousands of redundant allocations per scroll.

## Verification
- `dart analyze`: Clean analysis (0 errors, 0 new warnings).
- `flutter test`: All affected unit and widget tests pass.
