# Tech Stack

## Core Technologies
- **Framework**: [Flutter](https://flutter.dev) (SDK: `^3.12.2` / Dart 3.x)
- **Application Type**: Cross-platform Mobile & Web Application (Primary focus: Mobile, responsive Edge-to-Edge UI)
- **Design System**: Material Design 3 (`uses-material-design: true`) with bespoke design tokens

## Dependencies
- **Networking & HTTP**: `http: ^1.6.0` (REST API communication via HTTP Client)
- **Secure Persistence**: `flutter_secure_storage: ^11.2.0` (Encrypted token and credential storage with memory fallback)
- **Key-Value Storage**: `shared_preferences: ^2.5.6` (User settings and client-side preferences)
- **File & Media Handling**: `file_picker: ^13.1.0` (Document & attachment picking)
- **External Intent & Linking**: `url_launcher: ^6.3.3` (Phone dialing, WhatsApp launch, and browser linking)
- **Typography & Icons**: `cupertino_icons: ^1.0.8`, custom font `Helvetica Neue` (weights 100, 300, 400, 500, 700, Italic)

## Development & Tooling
- **Linting & Analysis**: `flutter_lints: ^6.0.0` with `analysis_options.yaml`
- **Icon Generation**: `flutter_launcher_icons: ^0.14.4` (Configured for Android, iOS, Web, Windows, macOS)
- **Testing**: `flutter_test` (built into Flutter SDK)

## Platform Targets
- **Android**: Min SDK 21, Adaptive icon configuration
- **iOS**: Clean alpha configuration

