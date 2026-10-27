/// Date formatting and parsing utilities.
library;

/// Formats any date string (ISO8601, MM/DD/YYYY, YYYY-MM-DD, DD/MM/YYYY, etc.)
/// into day/month/year format: DD/MM/YYYY.
String formatDateToDayMonthYear(String? dateStr) {
  if (dateStr == null) return '';
  final trimmed = dateStr.trim();
  if (trimmed.isEmpty) return '';

  final parsed = DateTime.tryParse(trimmed);
  if (parsed != null) {
    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    return '$d/$m/$y';
  }

  // Pre-process: if dateStr contains time or whitespace/comma, extract the date component
  String cleanDate = trimmed;
  if (cleanDate.contains(',')) {
    final segments = cleanDate.split(',');
    for (final seg in segments) {
      final s = seg.trim();
      if (s.contains('/') || s.contains('-')) {
        cleanDate = s;
        break;
      }
    }
  }

  if (cleanDate.contains(' ')) {
    final tokens = cleanDate.split(RegExp(r'\s+'));
    for (final token in tokens) {
      final t = token.trim();
      if (t.contains('/') || t.contains('-')) {
        cleanDate = t;
        break;
      }
    }
  }

  if (cleanDate.contains('T')) {
    cleanDate = cleanDate.split('T')[0].trim();
  }

  // Try parsing the cleaned date
  final cleanParsed = DateTime.tryParse(cleanDate);
  if (cleanParsed != null) {
    final local = cleanParsed.isUtc ? cleanParsed.toLocal() : cleanParsed;
    final d = local.day.toString().padLeft(2, '0');
    final m = local.month.toString().padLeft(2, '0');
    final y = local.year.toString();
    return '$d/$m/$y';
  }

  if (cleanDate.contains('/')) {
    final parts = cleanDate.split('/');
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        if (parts[0].length == 4) {
          final d = p2.toString().padLeft(2, '0');
          final m = p1.toString().padLeft(2, '0');
          return '$d/$m/${parts[0]}';
        }
        if (parts[2].length == 4) {
          if (p0 > 12) {
            // Already DD/MM/YYYY
            final d = p0.toString().padLeft(2, '0');
            final m = p1.toString().padLeft(2, '0');
            return '$d/$m/${parts[2]}';
          }
          // MM/DD/YYYY -> DD/MM/YYYY
          final d = p1.toString().padLeft(2, '0');
          final m = p0.toString().padLeft(2, '0');
          return '$d/$m/${parts[2]}';
        }
      }
    }
  }

  if (cleanDate.contains('-')) {
    final parts = cleanDate.split('-');
    if (parts.length == 3) {
      final p0 = int.tryParse(parts[0]);
      final p1 = int.tryParse(parts[1]);
      final p2 = int.tryParse(parts[2]);
      if (p0 != null && p1 != null && p2 != null) {
        if (parts[0].length == 4) {
          final d = p2.toString().padLeft(2, '0');
          final m = p1.toString().padLeft(2, '0');
          return '$d/$m/${parts[0]}';
        } else if (parts[2].length == 4) {
          if (p0 > 12) {
            final d = p0.toString().padLeft(2, '0');
            final m = p1.toString().padLeft(2, '0');
            return '$d/$m/${parts[2]}';
          }
          final d = p1.toString().padLeft(2, '0');
          final m = p0.toString().padLeft(2, '0');
          return '$d/$m/${parts[2]}';
        }
      }
    }
  }

  return cleanDate;
}
