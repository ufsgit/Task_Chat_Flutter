# Roadmap: Milestone 1 (v1.0)

## Phase Breakdown

### Phase 1: Test Stabilization & Quality Baseline
- **Goal**: Clean baseline, fix 3 failing widget/structure tests, and establish green test suite.
- **Deliverables**:
  - Fix `customer_details_structure_test.dart` (layout ordering and notes text placeholder).
  - Fix `metric_stat_card_test.dart` (percentage formatting).
  - Verify all 52 tests pass green while preserving existing local backend configuration.


### Phase 2: Complete Backend Integration & Mock Elimination
- **Goal**: Connect all feature modules to live/contract REST APIs, eliminating mock lists.
- **Deliverables**:
  - Replace `todayChatItems` global in-memory state with a clean data repository.
  - Implement real mutation calls for status updates in `UpdateStatusPage`.
  - Connect `AreaViewModel` and `AddBookingViewModel` to `GET /api/dropdowns`.
  - Add unified 401 token expiry and session renewal interceptor.

### Phase 3: Feature Expansion & Domain Enhancement
- **Goal**: Expand Bookings, Customer Details, and Reporting capabilities.
- **Deliverables**:
  - Enhanced multi-filter and date range filtering in `TodayPage` and `SuperAdminPage`.
  - Rich document attachment handling (preview, categorization, progress indicator).
  - Dynamic analytics in `DashboardPage` and `ReportActivityPage`.

### Phase 4: Verification, Hardening & Release Prep
- **Goal**: Comprehensive regression testing, responsive audit across mobile & web, and release readiness.
- **Deliverables**:
  - Full automated test suite verification.
  - Visual verification with edge-to-edge system chrome checks.
  - Verification report & milestone completion.
