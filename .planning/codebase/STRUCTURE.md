# Codebase Structure

```
task_chat/
├── assets/
│   ├── fonts/                     # Helvetica Neue font weights
│   └── images/                    # App logos, brand banners, icons
├── lib/
│   ├── main.dart                  # Application entry point & theme initialization
│   ├── api/                       # API configuration & base endpoints
│   │   └── api.dart
│   ├── bottom_navigator/          # Floating bottom navigation bar & main tab shell
│   │   └── bottom_navigator.dart
│   ├── core/                      # Global theme, shared widgets, transitions
│   │   ├── theme.dart             # AppColors, AppTheme, ThemeController
│   │   ├── circular_back_button.dart
│   │   ├── slide_up_route.dart
│   │   └── widgets/               # Shared UI elements (chips, avatar, logo)
│   ├── customer_details/          # Customer CRM profile, documents, status actions
│   │   ├── customer_details_model.dart
│   │   ├── customer_details_view.dart
│   │   ├── customer_details_view_model.dart
│   │   └── widgets/               # Contact cards, header card, documents card
│   ├── dashboard/                 # Analytics, metrics, progress bars
│   │   ├── dashboard_page.dart
│   │   ├── dashboard_data.dart
│   │   └── widgets/               # MetricStatCard, BookingProgressCard, filter bar
│   ├── login_page/                # Authentication, token storage, session management
│   │   ├── login_model.dart
│   │   ├── login_view.dart
│   │   ├── login_view_model.dart
│   │   └── token_storage.dart
│   ├── new_booking/               # Lead entry form, area selector, document intake
│   │   ├── add_booking_view.dart
│   │   ├── add_booking_view_model.dart
│   │   ├── area_model.dart
│   │   ├── area_view_model.dart
│   │   ├── lead_data.dart
│   │   └── widgets/               # AreaSelectorDropdown, LeadDocumentUploadCard
│   ├── notification_page/         # System & task notifications
│   │   ├── notification_page.dart
│   │   ├── notification_data.dart
│   │   └── widgets/
│   ├── report_activity/           # Activity logs, staff performance, bar charts
│   │   ├── activity_page.dart
│   │   ├── report_data.dart
│   │   ├── task_report_page.dart
│   │   └── widgets/
│   ├── settings/                  # User profile, theme mode toggle, logout
│   │   ├── settings_model.dart
│   │   ├── settings_view.dart
│   │   ├── settings_view_model.dart
│   │   └── widgets/
│   ├── splash/                    # Animated splash screen with auto-navigation
│   │   └── splash_screen.dart
│   ├── super_admin/               # Super admin operations & coordinator filters
│   │   ├── super_admin_page.dart
│   │   ├── super_admin_data.dart
│   │   └── widgets/
│   ├── today/                     # Primary chat/booking list with search & chips
│   │   ├── today_model.dart
│   │   ├── today_view.dart
│   │   ├── today_view_model.dart
│   │   └── widgets/               # ChatListItemTile, SearchInputField, skeletons
│   └── update_status/             # Status transition workflow, scheduling & notes
│       ├── update_status_page.dart
│       ├── super_admin_update_status_page.dart
│       ├── update_status_data.dart
│       └── widgets/
├── test/                          # Unit and widget test suite
│   ├── add_booking_view_model_test.dart
│   ├── area_view_model_test.dart
│   ├── customer_details_view_model_test.dart
│   ├── customer_details_structure_test.dart
│   ├── login_view_model_test.dart
│   ├── metric_stat_card_test.dart
│   ├── settings_page_test.dart
│   ├── today_view_model_test.dart
│   └── ... (18 test files total)
└── pubspec.yaml                   # Manifest, package dependencies, asset rules
```
