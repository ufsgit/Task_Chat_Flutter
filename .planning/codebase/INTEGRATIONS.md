# External Integrations & Services

## Backend REST API
All API endpoints are centralized in [`lib/api/api.dart`](file:///c:/task_chat/lib/api/api.dart):
- **Base URL**: `https://7qh4z02n-5000.inc1.devtunnels.ms` (Configured via `ApiConfig.baseUrl`)
- **Authentication**: `POST /api/auth/mobile-login`
  - Accepts username/password payload
  - Returns `sessionToken` / `token` / `access_token` and user object with coordinator / super-admin flags
- **Bookings**: `GET /api/bookings`
  - Retrieves customer bookings and chat conversation items
  - Authorized via Bearer token in the `authorization` header
- **Dropdowns & Master Data**: `GET /api/dropdowns` (`ApiConfig.area_listing`)
  - Loads branch/area listings for bookings and lead assignments

## Local Persistence & Secure Storage
- **TokenStorage**: [`lib/login_page/token_storage.dart`](file:///c:/task_chat/lib/login_page/token_storage.dart)
  - Uses `FlutterSecureStorage` with keys `access_token` and legacy `access-token`
  - Includes a thread-safe `_memoryCache` and `useMemoryOnly` toggle for fast mock testing without platform channels
- **SharedPreferences**:
  - Used for persistent user settings, theme preferences, and local user state caching

## Device & Platform Integrations
- **File System / Media**:
  - `file_picker` used across `lib/update_status/widgets/attach_documents_card.dart`, `lib/new_booking/widgets/lead_document_upload_card.dart`, and `lib/customer_details/widgets/customer_documents_card.dart`
- **External Communication & Calling**:
  - `url_launcher` used in `lib/customer_details/widgets/contact_actions_card.dart` for direct phone calls (`tel:`) and WhatsApp messaging (`https://wa.me/`)
- **System Chrome Overlays**:
  - Orientation locked to portrait in [`lib/main.dart`](file:///c:/task_chat/lib/main.dart)
  - Edge-to-edge transparent system navigation and status bar style applied via `SystemChrome.setSystemUIOverlayStyle`
