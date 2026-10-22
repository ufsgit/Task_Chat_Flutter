# Code Conventions & Practices

## Code Style & Formatting
- **Linter**: `package:flutter_lints/flutter.yaml` enforced via `analysis_options.yaml`.
- **Constructors**: Prefer `const` constructors wherever possible for optimal widget tree reconciliation.
- **Null Safety**: 100% sound null safety with explicit nullable types and null-aware operators.
- **Naming Conventions**:
  - Files: `snake_case.dart`
  - Classes: `PascalCase`
  - Variables & Functions: `camelCase`
  - Constants & Design Tokens: `lowerCamelCase` or `PascalCase` within abstract final classes (e.g. `AppColors.primaryGreen`)

## Design & UI Guidelines
- **Palette**: Clean Slate / WhatsApp inspired color scheme:
  - Base green: `AppColors.primaryGreen` (`#16A34A`)
  - Backgrounds: `AppColors.surfaceWhite` (`#FFFFFF`), `AppColors.surfaceGrey` (`#F1F5F9`)
  - Text: `AppColors.textPrimary` (`#111B21`), `AppColors.textSecondary` (`#334155`), `AppColors.textSubtitle` (`#667781`)
- **Typography**: Custom `Helvetica Neue` with consistent scaling:
  - Display/Headline: 20–24pt SemiBold/Bold
  - Body/Subtitles: 13–15pt Regular/Medium
- **Layout Integrity**: Always avoid hardcoded heights that could trigger `RenderFlex` overflows on small devices. Wrap scrollable cards in `SingleChildScrollView` or `ListView`.

## Architecture & State Conventions
- **ViewModel DI**: ViewModels must allow constructor injection of `http.Client` and `TokenStorage` to enable hermetic testing:
  ```dart
  LoginViewModel({http.Client? client, TokenStorage? tokenStorage})
      : _client = client ?? http.Client(),
        _tokenStorage = tokenStorage ?? TokenStorage();
  ```
- **Disposal**: Any created `TextEditingController`, `AnimationController`, or `http.Client` owned by a widget/ViewModel must be closed in `dispose()`.

## Developer Workflow Rules
- **Live Updates**: When editing Dart or Flutter files in this project:
  1. Proactively connect to running instances via the `dtd` tool.
  2. Perform a hot reload using the `hot_reload` tool to reflect updates immediately.
