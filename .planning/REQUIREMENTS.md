# Requirements: Milestone 1 — Backend Integration & Feature Expansion

## 1. Backend Integration & Data Realism
- **REQ-INT-01**: Local Backend Preservation: Preserve existing local backend configuration (`ApiConfig.baseUrl`) and API architecture as the expected development environment without modifying networking endpoints unless explicitly requested.
- **REQ-INT-02**: Full API Contract for Bookings:
  - Wire booking status changes directly to API mutations (`PATCH /api/bookings/{id}`).
  - Eliminate top-level `todayChatItems` global mutable array; introduce reactive repository/service layer.
- **REQ-INT-03**: Dynamic Area & Dropdown APIs:
  - Populate area selectors, branch lists, and lead stages dynamically from `GET /api/dropdowns`.
- **REQ-INT-04**: Customer Details & Contact Actions:
  - Integrate real customer profile endpoint (`GET /api/customers/{id}`) and update endpoints (`PUT /api/customers/{id}`).
  - Support multi-document upload and download attachments with real storage URLs.

## 2. Feature Expansion & Module Enhancements
- **REQ-FEAT-01**: Enhanced Bookings Management:
  - Batch filtering by date range, branch manager, and status.
  - Quick action swipe / inline status updates from the Today list.
- **REQ-FEAT-02**: Customer Details CRM:
  - Rich document preview and categorized attachments (Invoices, Photos, IDs).
  - Activity log history on customer detail timeline.
- **REQ-FEAT-03**: Reporting & Analytics:
  - Connect `report_activity` and `dashboard` to real aggregation endpoints.
  - Export report capabilities (PDF / CSV summaries).

## 3. Quality & Stabilization
- **REQ-QUAL-01**: Resolve existing 3 failing widget/structure tests in `customer_details_structure_test.dart` and `metric_stat_card_test.dart`.
- **REQ-QUAL-02**: Ensure all ViewModel network calls handle timeouts, offline status, and 401 unauthorized token expirations gracefully.
