# Project: Fitmate (Task Chat)

## Executive Summary
Fitmate is a mobile application built with Flutter designed for customer booking coordination, task tracking, and field activity reporting. It connects coordinators, super admins, and field staff with customer CRM profiles, dynamic booking statuses, document attachments, and performance analytics.currently testing in web.

## Core Problem & Value Proposition
- Handles booking of clients.
- Provides real-time booking status transitions (New, Scheduled, Completed, Cancelled).
- Offers comprehensive reporting and performance dashboards for branch managers and coordinators.

## Technology Stack
- **Framework**: Flutter (SDK: `^3.12.2` / Dart 3.x) with Sound Null Safety
- **Design Tokens**: Custom WhatsApp-inspired palette driven by `AppColors.primaryGreen` (`#16A34A`)
- **State Management**: MVVM with `ChangeNotifier` ViewModels and reactive `ThemeController`
- **Networking & Persistence**: `http: ^1.6.0`, `flutter_secure_storage: ^11.2.0`, `shared_preferences: ^2.5.6`
- **Device Capabilities**: `url_launcher: ^6.3.3`, `file_picker: ^13.1.0`

## Architecture Highlights
- Layered separation: `lib/core` (theming, shared widgets), `lib/api` (central endpoint definitions), feature directories (`customer_details`, `new_booking`, `today`, `dashboard`, `report_activity`, `settings`, `super_admin`, `update_status`).
- Dependency injection pattern on ViewModels (`client`, `tokenStorage`) for testing.
