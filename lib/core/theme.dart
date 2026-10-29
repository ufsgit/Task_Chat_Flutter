import 'package:flutter/material.dart';
import 'widgets/circular_back_button.dart';

/// Centralized color palette and theme configurations for Fitmate.
/// Contains only the colors actively used across the app.
abstract final class AppColors {
  // ===========================================================================
  // PRIMARY GREEN (ONE CENTRAL VARIABLE TO TEST DIFFERENT GREENS)
  // Change this single color to change the green theme everywhere across the app!
  // ===========================================================================
  static const Color primaryGreen = Color(0xFF16A34A);

  // --- Aliased Green Tokens (driven by primaryGreen) ---
  static const Color brandGreen = primaryGreen;
  static const Color whatsappGreen = primaryGreen;

  // --- Backgrounds & Surfaces ---
  static const Color scaffoldBackground = surfaceWhite;
  static const Color surfaceWhite = Colors.white;
  static const Color surfaceGrey = Color(0xFFF1F5F9);
  static const Color surfaceGreyLight = Color(0xFFF4F7FB);

  // --- Text & Neutral Colors (WhatsApp / Clean Slate Palette) ---
  static const Color textPrimary = Color(0xFF111B21);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textSubtitle = Color(0xFF667781);
  static const Color textPlaceholder = Color(0xFF8696A0);

  // --- Borders & Dividers ---
  static const Color border = Color(0xFFE9EDEF);
  static const Color divider = Color(0xFFE2E8F0);

  // --- Status & Tag Colors ---
  // Cancelled / Red
  static const Color cancelledBg = Color(0xFFFFEBEB);
  static const Color cancelledText = Color(0xFFE53935);

  // Completed / Green
  static const Color completedBg = Color(0xFFDCFCE7);
  static const Color completedText = primaryGreen;

  // New / Blue
  static const Color newBg = Color(0xFFDBEAFE);
  static const Color newText = Color(0xFF2563EB);
  static const Color newAvatarBg = Color(0xFFE0F2FE);
  static const Color newAvatarText = Color(0xFF0284C7);

  // In-Progress
  static const Color inProgressBg = Color(0xFFE0F2FE);
  static const Color inProgressText = Color(0xFF0284C7);

  // Scheduled / Amber Orange
  static const Color scheduledBg = Color(0xFFFEF3C7);
  static const Color scheduledText = Color(0xFFD97706);

  // Chips & Filters
  static const Color chipPendingBg = Color(0xFFD4F4DD);
  static const Color chipPendingText = primaryGreen;
  static const Color chipUnselectedBg = Color(0xFFF1F5F9);
  static const Color chipUnselectedText = Color(0xFF64748B);

  // Avatar Accents & Badges
  static const Color purpleAvatarBg = Color(0xFFEDE9FE);
  static const Color purpleAvatarText = Color(0xFF7C3AED);
  static const Color verifiedBadge = primaryGreen;

  // Dropdowns & Menus
  static const Color dropdownBackground = Colors.white;
  static const Color dropdownItemText = Color(0xFF111B21);
}

/// Global theme data definitions for Fitmate.
abstract final class AppTheme {
  /// Shared text theme generator preventing duplication across light and dark modes.
  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
    required Color subtitle,
  }) {
    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.4,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.3,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.2,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.2,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 19,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.2,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.2,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: -0.1,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.4,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.4,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        color: subtitle,
        height: 1.35,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 14.5,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.1,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: subtitle,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Helvetica Neue',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: subtitle,
      ),
    );
  }

  /// Shared elevated button theme generator.
  static ElevatedButtonThemeData _buildButtonTheme(Color bgColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: 'Helvetica Neue',
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      ),
    );
  }

  /// Shared popup menu theme generator.
  static PopupMenuThemeData _buildPopupMenuTheme({
    required Color backgroundColor,
    required Color borderColor,
    required Color itemTextColor,
    required double shadowAlpha,
  }) {
    return PopupMenuThemeData(
      color: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: shadowAlpha),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: 1),
      ),
      textStyle: TextStyle(
        fontFamily: 'Helvetica Neue',
        color: itemTextColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// Shared menu style generator for DropdownMenu and MenuTheme.
  static MenuStyle _buildMenuStyle({
    required Color backgroundColor,
    required Color borderColor,
    required double shadowAlpha,
  }) {
    return MenuStyle(
      backgroundColor: WidgetStatePropertyAll<Color>(backgroundColor),
      surfaceTintColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
      elevation: const WidgetStatePropertyAll<double>(4),
      shadowColor: WidgetStatePropertyAll<Color>(
        Colors.black.withValues(alpha: shadowAlpha),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),
    );
  }

  /// Light Theme configuration.
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Helvetica Neue',
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        surface: AppColors.surfaceWhite,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      appBarTheme: const AppBarTheme(
        toolbarHeight: 68.0,
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Helvetica Neue',
          color: AppColors.brandGreen,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: _buildButtonTheme(AppColors.whatsappGreen),
      textTheme: _buildTextTheme(
        primary: AppColors.textPrimary,
        secondary: AppColors.textSecondary,
        subtitle: AppColors.textSubtitle,
      ),
      popupMenuTheme: _buildPopupMenuTheme(
        backgroundColor: AppColors.dropdownBackground,
        borderColor: AppColors.border,
        itemTextColor: AppColors.dropdownItemText,
        shadowAlpha: 0.12,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: _buildMenuStyle(
          backgroundColor: AppColors.dropdownBackground,
          borderColor: AppColors.border,
          shadowAlpha: 0.12,
        ),
      ),
      menuTheme: MenuThemeData(
        style: _buildMenuStyle(
          backgroundColor: AppColors.dropdownBackground,
          borderColor: AppColors.border,
          shadowAlpha: 0.12,
        ),
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (BuildContext context) => const CircularBackButton(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Helvetica Neue',
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: Color(0xFF0F172A),
        ),
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
    );
  }

  /// Custom transitions builder that slides incoming pages down from top to bottom.
  static const PageTransitionsTheme _pageTransitionsTheme =
      PageTransitionsTheme(
    builders: {
      TargetPlatform.android: TopToBottomPageTransitionsBuilder(),
      TargetPlatform.iOS: TopToBottomPageTransitionsBuilder(),
      TargetPlatform.windows: TopToBottomPageTransitionsBuilder(),
      TargetPlatform.macOS: TopToBottomPageTransitionsBuilder(),
      TargetPlatform.linux: TopToBottomPageTransitionsBuilder(),
      TargetPlatform.fuchsia: TopToBottomPageTransitionsBuilder(),
    },
  );

  /// Dark Mode Theme configuration.
  static ThemeData get darkTheme {
    return ThemeData(
      fontFamily: 'Helvetica Neue',
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppDarkColors.primaryGreen,
        surface: AppDarkColors.surfaceCard,
        onSurface: AppDarkColors.textPrimary,
        onPrimary: Color(0xFF111B21),
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppDarkColors.scaffoldBackground,
      cardColor: AppDarkColors.surfaceCard,
      dividerColor: AppDarkColors.divider,
      appBarTheme: const AppBarTheme(
        toolbarHeight: 68.0,
        backgroundColor: AppDarkColors.scaffoldBackground,
        foregroundColor: AppDarkColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: 'Helvetica Neue',
          color: AppDarkColors.primaryGreen,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      elevatedButtonTheme: _buildButtonTheme(AppDarkColors.primaryGreen),
      textTheme: _buildTextTheme(
        primary: AppDarkColors.textPrimary,
        secondary: AppDarkColors.textSecondary,
        subtitle: AppDarkColors.textSubtitle,
      ),
      popupMenuTheme: _buildPopupMenuTheme(
        backgroundColor: AppDarkColors.dropdownBackground,
        borderColor: AppDarkColors.border,
        itemTextColor: AppDarkColors.dropdownItemText,
        shadowAlpha: 0.3,
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: _buildMenuStyle(
          backgroundColor: AppDarkColors.dropdownBackground,
          borderColor: AppDarkColors.border,
          shadowAlpha: 0.3,
        ),
      ),
      menuTheme: MenuThemeData(
        style: _buildMenuStyle(
          backgroundColor: AppDarkColors.dropdownBackground,
          borderColor: AppDarkColors.border,
          shadowAlpha: 0.3,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppDarkColors.dropdownBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titleTextStyle: const TextStyle(
          fontFamily: 'Helvetica Neue',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppDarkColors.textPrimary,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Helvetica Neue',
          fontSize: 14.5,
          color: AppDarkColors.textSecondary,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppDarkColors.surfaceCard,
        modalBackgroundColor: AppDarkColors.surfaceCard,
      ),
      actionIconTheme: ActionIconThemeData(
        backButtonIconBuilder: (BuildContext context) => const CircularBackButton(),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppDarkColors.surfaceCard,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: const BorderSide(color: AppDarkColors.border, width: 1),
        ),
        contentTextStyle: const TextStyle(
          fontFamily: 'Helvetica Neue',
          fontSize: 14.5,
          fontWeight: FontWeight.w500,
          color: AppDarkColors.textPrimary,
        ),
      ),
      pageTransitionsTheme: _pageTransitionsTheme,
    );
  }
}

/// Page transitions builder sliding pages in from the top to bottom.
class TopToBottomPageTransitionsBuilder extends PageTransitionsBuilder {
  const TopToBottomPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    const begin = Offset(0.0, -1.0);
    const end = Offset.zero;
    const curve = Curves.easeOutCubic;

    final tween = Tween(begin: begin, end: end).chain(
      CurveTween(curve: curve),
    );

    return SlideTransition(
      position: animation.drive(tween),
      child: child,
    );
  }
}

/// Global scroll behavior applying bouncing scroll physics with always-scrollable parent across all scrollables.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

/// Sleek Dark Mode Palette matching the design reference.
abstract final class AppDarkColors {
  // Vibrant emerald green accents (WhatsApp Green)
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color whatsappGreen = primaryGreen;
  static const Color brandGreen = primaryGreen;

  // Backgrounds: Deep Midnight Charcoal & Sleek Elevated Cards
  static const Color scaffoldBackground = Color(0xFF0F1115);
  static const Color surface = Color(0xFF16191E);
  static const Color surfaceCard = Color(0xFF16191E);
  static const Color surfaceGrey = Color(0xFF16191E);
  static const Color surfaceGreyLight = Color(0xFF1F242C);
  static const Color surfaceSecondary = Color(0xFF101317);

  // Text & Neutral Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textSubtitle = Color(0xFF94A3B8);
  static const Color textPlaceholder = Color(0xFF64748B);

  // Borders & Dividers
  static const Color border = Color(0xFF22262E);
  static const Color divider = Color(0xFF1E222A);

  // Status & Badges
  static const Color completedBg = Color(0xFF0D281E);
  static const Color completedText = primaryGreen;
  static const Color cancelledBg = Color(0xFF38161A);
  static const Color cancelledText = Color(0xFFEF4444);
  static const Color newBg = Color(0xFF112240);
  static const Color newText = Color(0xFF38BDF8);
  static const Color inProgressBg = Color(0xFF112240);
  static const Color inProgressText = Color(0xFF38BDF8);
  static const Color scheduledBg = Color(0xFF452B0E);
  static const Color scheduledText = Color(0xFFFBBF24);

  // Chips & Avatar backgrounds
  static const Color chipPendingBg = Color(0xFF0D281E);
  static const Color pillActiveBg = Color(0xFF0D281E);
  static const Color chipPendingText = primaryGreen;
  static const Color chipUnselectedBg = Color(0xFF16191E);
  static const Color chipUnselectedText = Color(0xFF94A3B8);

  // Dropdowns & Dialogs
  static const Color dropdownBackground = Color(0xFF16191E);
  static const Color dropdownItemText = Colors.white;
}

/// Centralized light/dark color resolver.
/// Eliminates having to write `isDark ? AppDarkColors.x : AppColors.x` in widgets.
class AppThemeColors {
  final bool isDark;

  const AppThemeColors({required this.isDark});

  // Backgrounds & Surfaces
  Color get scaffoldBg =>
      isDark ? AppDarkColors.scaffoldBackground : AppColors.scaffoldBackground;
  Color get surfaceCard =>
      isDark ? AppDarkColors.surfaceCard : AppColors.surfaceWhite;
  Color get cardBg => surfaceCard;
  Color get surfaceSecondary =>
      isDark ? AppDarkColors.surfaceSecondary : const Color(0xFFF7F8FA);
  Color get surfaceGrey =>
      isDark ? AppDarkColors.surfaceGrey : AppColors.surfaceGrey;
  Color get avatarBg =>
      isDark ? AppDarkColors.chipPendingBg : const Color(0xFFD3F9E0);

  // Text & Neutral Colors
  Color get textPrimary =>
      isDark ? AppDarkColors.textPrimary : AppColors.textPrimary;
  Color get textSecondary =>
      isDark ? AppDarkColors.textSecondary : AppColors.textSecondary;
  Color get textSubtitle =>
      isDark ? AppDarkColors.textSubtitle : AppColors.textSubtitle;
  Color get textPlaceholder =>
      isDark ? AppDarkColors.textPlaceholder : AppColors.textPlaceholder;

  // Borders & Dividers
  Color get border => isDark ? AppDarkColors.border : AppColors.border;
  Color get divider => isDark ? AppDarkColors.divider : AppColors.divider;

  // Brand Green Accents
  Color get primaryGreen =>
      isDark ? AppDarkColors.primaryGreen : AppColors.primaryGreen;
  Color get whatsappGreen =>
      isDark ? AppDarkColors.whatsappGreen : AppColors.whatsappGreen;
  Color get brandGreen =>
      isDark ? AppDarkColors.brandGreen : AppColors.brandGreen;
  Color get pillActiveBg =>
      isDark ? AppDarkColors.pillActiveBg : const Color(0xFFE7FCE3);

  // Status Badges & Chips
  Color get completedBg =>
      isDark ? AppDarkColors.completedBg : AppColors.completedBg;
  Color get completedText =>
      isDark ? AppDarkColors.completedText : AppColors.completedText;
  Color get cancelledBg =>
      isDark ? AppDarkColors.cancelledBg : AppColors.cancelledBg;
  Color get cancelledText =>
      isDark ? AppDarkColors.cancelledText : AppColors.cancelledText;
  Color get newBg => isDark ? AppDarkColors.newBg : AppColors.newBg;
  Color get newText => isDark ? AppDarkColors.newText : AppColors.newText;
  Color get chipUnselectedBg =>
      isDark ? AppDarkColors.chipUnselectedBg : AppColors.chipUnselectedBg;
  Color get chipUnselectedText =>
      isDark ? AppDarkColors.chipUnselectedText : AppColors.chipUnselectedText;

  // Dropdowns
  Color get dropdownBg =>
      isDark ? AppDarkColors.dropdownBackground : AppColors.dropdownBackground;
  Color get dropdownItemText =>
      isDark ? AppDarkColors.dropdownItemText : AppColors.dropdownItemText;
}

/// Extension on BuildContext for quick and clean theme color access.
///
/// Example usage in any widget:
/// ```dart
/// final colors = context.colors;
/// Container(
///   color: colors.cardBg,
///   child: Text('Hello', style: TextStyle(color: colors.textPrimary)),
/// );
/// ```
extension ThemeContextExtension on BuildContext {
  /// Whether dark mode is currently active.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Centralized semantic color tokens for the active theme.
  AppThemeColors get colors => AppThemeColors(isDark: isDark);

  // Direct shorthands on BuildContext:
  Color get scaffoldBg => colors.scaffoldBg;
  Color get cardBg => colors.cardBg;
  Color get textPrimary => colors.textPrimary;
  Color get textSubtitle => colors.textSubtitle;
  Color get textSecondary => colors.textSecondary;
  Color get border => colors.border;
  Color get divider => colors.divider;
  Color get primaryGreen => colors.primaryGreen;
}

/// Global Theme Controller to switch between System, Light, and Dark mode like WhatsApp.
class ThemeController {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
    ThemeMode.light,
  );

  ThemeMode get themeMode => themeModeNotifier.value;

  String get themeModeLabel {
    switch (themeMode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  void setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
  }

  bool isDark(BuildContext context) {
    if (themeMode == ThemeMode.dark) return true;
    if (themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}

/// WhatsApp-style "Choose theme" modal dialog.
Future<void> showWhatsAppThemeDialog(BuildContext context) async {
  final controller = ThemeController.instance;
  ThemeMode selected = controller.themeMode;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final colors = dialogContext.colors;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          Widget buildOption(String label, ThemeMode mode) {
            final isOptionSelected = selected == mode;
            return InkWell(
              onTap: () {
                setDialogState(() {
                  selected = mode;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      isOptionSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: isOptionSelected
                          ? colors.primaryGreen
                          : colors.textSubtitle,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Helvetica Neue',
                        fontSize: 15.5,
                        fontWeight: isOptionSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: colors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return AlertDialog(
            backgroundColor: colors.dropdownBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            title: Text(
              'Choose theme',
              style: TextStyle(
                fontFamily: 'Helvetica Neue',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildOption('System default', ThemeMode.system),
                buildOption('Light', ThemeMode.light),
                buildOption('Dark', ThemeMode.dark),
              ],
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: colors.primaryGreen,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  controller.setThemeMode(selected);
                  Navigator.of(dialogContext).pop();
                },
                child: Text(
                  'OK',
                  style: TextStyle(
                    fontFamily: 'Helvetica Neue',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: colors.primaryGreen,
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
