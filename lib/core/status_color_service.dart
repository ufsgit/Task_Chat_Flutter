import 'package:flutter/material.dart';
import '../update_status/models/status_chip_model.dart';
import 'widgets/user_circle_avatar.dart';

/// Centralized service to manage and resolve status colors from backend API.
/// Maps backend status codes and labels to their respective backend-defined hex color codes.
class StatusColorService {
  StatusColorService._();

  /// In-memory cache of status colors dynamically populated from backend GET /api/status
  /// or inline status_color_code payloads.
  static final Map<String, Color> _statusColors = {
    'new': const Color(0xFF3B82F6),        // #3b82f6
    'scheduled': const Color(0xFF7C3AED),  // #7c3aed (backend status code from /api/status)
    'completed': const Color(0xFF10B981),  // #10b981
    'cancelled': const Color(0xFFEF4444),  // #ef4444
    'pending': const Color(0xFF8B5CF6),    // #8b5cf6
    'in-progress': const Color(0xFF7C3AED),
    'in progress': const Color(0xFF7C3AED),
  };

  /// Registers a status color from hex string (e.g. "#3b82f6").
  static void registerStatus(String? status, String? colorHex) {
    if (status == null || status.trim().isEmpty) return;
    final color = parseHexColor(colorHex);
    if (color != null) {
      _statusColors[status.trim().toLowerCase()] = color;
    }
  }

  /// Bulk registers status chips fetched from GET /api/status.
  static void registerChips(Iterable<StatusChipModel>? chips) {
    if (chips == null) return;
    for (final chip in chips) {
      if (chip.colorCode != null && chip.colorCode!.isNotEmpty) {
        registerStatus(chip.code, chip.colorCode);
        registerStatus(chip.label, chip.colorCode);
      }
    }
  }

  /// Safely parses a hex color string (e.g. "#3b82f6" or "3b82f6") into a Flutter [Color].
  static Color? parseHexColor(String? hexString) {
    if (hexString == null || hexString.trim().isEmpty) return null;
    var hex = hexString.replaceAll('#', '').trim();
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length == 8) {
      final val = int.tryParse(hex, radix: 16);
      if (val != null) return Color(val);
    }
    return null;
  }

  /// Resolves the primary status color from backend registry or customColor override.
  static Color getColor(
    String? status, {
    Color? customColor,
    Color? fallback,
  }) {
    if (customColor != null) return customColor;
    if (status == null || status.trim().isEmpty) {
      return fallback ?? _statusColors['new']!;
    }
    final key = status.trim().toLowerCase();
    if (_statusColors.containsKey(key)) {
      return _statusColors[key]!;
    }
    // Partial substring matches
    if (key.contains('complet') || key.contains('done')) {
      return _statusColors['completed']!;
    }
    if (key.contains('cancel')) {
      return _statusColors['cancelled']!;
    }
    if (key.contains('sched')) {
      return _statusColors['scheduled']!;
    }
    if (key.contains('pend')) {
      return _statusColors['pending']!;
    }
    if (key.contains('new')) {
      return _statusColors['new']!;
    }
    return fallback ?? _statusColors['new']!;
  }

  /// Returns badge colors: background, text, and indicator dot.
  static ({Color bg, Color text, Color dot}) getBadgeColors(
    String? status, {
    bool isDark = false,
    Color? customColor,
  }) {
    final primary = getColor(status, customColor: customColor);
    return (
      bg: primary.withValues(alpha: isDark ? 0.22 : 0.12),
      text: primary,
      dot: primary,
    );
  }

  /// Resolves background and icon colors for circular avatars.
  static AvatarColorPair getAvatarColors(
    String? status, {
    bool isDark = false,
    Color? customColor,
  }) {
    if (customColor != null) {
      return AvatarColorPair(
        background: customColor.withValues(alpha: isDark ? 0.22 : 0.15),
        icon: customColor,
      );
    }
    return getAvatarColorsForStatus(status, isDark: isDark);
  }

  /// Resets in-memory cache to default backend mapping.
  static void resetToDefaults() {
    _statusColors
      ..clear()
      ..addAll({
        'new': const Color(0xFF3B82F6),
        'scheduled': const Color(0xFF7C3AED),
        'completed': const Color(0xFF10B981),
        'cancelled': const Color(0xFFEF4444),
        'pending': const Color(0xFF8B5CF6),
        'in-progress': const Color(0xFF7C3AED),
        'in progress': const Color(0xFF7C3AED),
      });
  }
}

