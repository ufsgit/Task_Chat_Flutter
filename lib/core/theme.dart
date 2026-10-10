import 'package:flutter/material.dart';

/// Centralized color palette and theme configurations for TaskChat.
/// Contains only the colors actively used across the app.
abstract final class AppColors {
  // --- Brand & Primary Colors ---
  static const Color brandGreen = Color(0xFF00A859);
  static const Color primaryGreen = Color(0xFF036838);
  static const Color activeGreen = Color(0xFF16A34A);
  static const Color emerald = Color(0xFF10B981);

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
  static const Color completedText = Color(0xFF15803D);
  static const Color completedIndicator = Color(0xFF22C55E);

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
  static const Color chipPendingText = Color(0xFF15803D);
  static const Color chipUnselectedBg = Color(0xFFF1F5F9);
  static const Color chipUnselectedText = Color(0xFF64748B);

  // Avatar Accents & Badges
  static const Color purpleAvatarBg = Color(0xFFEDE9FE);
  static const Color purpleAvatarText = Color(0xFF7C3AED);
  static const Color cyanIndicator = Color(0xFF06B6D4);
  static const Color verifiedBadge = Color(0xFF22C55E);
}

/// Global theme data definitions for TaskChat.
abstract final class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
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
    );
  }
}

