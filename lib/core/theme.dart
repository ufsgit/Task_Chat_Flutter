import 'package:flutter/material.dart';

/// Centralized color palette and theme configurations for TaskChat.
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
  static const Color activeGreen = primaryGreen;
  static const Color emerald = primaryGreen;

  // --- Backgrounds & Surfaces ---
  static const Color scaffoldBackground = Color(0xFFF3F7FC);
  static const Color surfaceWhite = Colors.white;
  static const Color surfaceGrey = Color(0xFFF1F5F9);
  static const Color surfaceGreyLight = Color(0xFFF4F7FB);

  // --- Text & Neutral Colors (Slate Palette) ---
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textSubtitle = Color(0xFF64748B);
  static const Color textPlaceholder = Color(0xFF94A3B8);

  // --- Borders & Dividers ---
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // --- Status & Tag Colors ---
  // Cancelled / Red
  static const Color cancelledBg = Color(0xFFFFEBEB);
  static const Color cancelledText = Color(0xFFE53935);
  static const Color cancelledIndicator = Color(0xFFFA5A3A);

  // Completed / Green
  static const Color completedBg = Color(0xFFDCFCE7);
  static const Color completedText = primaryGreen;
  static const Color completedIndicator = primaryGreen;

  // New / Blue
  static const Color newBg = Color(0xFFDBEAFE);
  static const Color newText = Color(0xFF2563EB);
  static const Color newIndicator = Color(0xFFF59E0B);
  static const Color newAvatarBg = Color(0xFFE0F2FE);
  static const Color newAvatarText = Color(0xFF0284C7);

  // In-Progress
  static const Color inProgressBg = Color(0xFFE0F2FE);
  static const Color inProgressText = Color(0xFF0284C7);
  static const Color inProgressIndicator = Color(0xFFF59E0B);

  // Chips & Filters
  static const Color chipPendingBg = Color(0xFFD4F4DD);
  static const Color chipPendingText = primaryGreen;
  static const Color chipUnselectedBg = Color(0xFFF1F5F9);
  static const Color chipUnselectedText = Color(0xFF64748B);

  // Avatar Accents & Badges
  static const Color purpleAvatarBg = Color(0xFFEDE9FE);
  static const Color purpleAvatarText = Color(0xFF7C3AED);
  static const Color cyanIndicator = Color(0xFF06B6D4);
  static const Color verifiedBadge = primaryGreen;

  // Dropdowns & Menus
  static const Color dropdownBackground = Colors.white;
  static const Color dropdownItemText = Color(0xFF0F172A);
}

/// Global theme data definitions for TaskChat.
abstract final class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        surface: AppColors.surfaceWhite,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.scaffoldBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceWhite,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.brandGreen,
          fontSize: 24,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.whatsappGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.dropdownBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        textStyle: const TextStyle(
          color: AppColors.dropdownItemText,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll<Color>(
            AppColors.dropdownBackground,
          ),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
          elevation: const WidgetStatePropertyAll<double>(4),
          shadowColor: WidgetStatePropertyAll<Color>(
            Colors.black.withValues(alpha: 0.12),
          ),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border, width: 1),
            ),
          ),
        ),
      ),
      menuTheme: MenuThemeData(
        style: MenuStyle(
          backgroundColor: const WidgetStatePropertyAll<Color>(
            AppColors.dropdownBackground,
          ),
          surfaceTintColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
          elevation: const WidgetStatePropertyAll<double>(4),
          shape: WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: AppColors.border, width: 1),
            ),
          ),
        ),
      ),
    );
  }
}
