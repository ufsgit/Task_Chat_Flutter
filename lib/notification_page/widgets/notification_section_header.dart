import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Section header band for notifications list (e.g. TODAY, THIS WEEK, EARLIER).
class NotificationSectionHeader extends StatelessWidget {
  final String title;

  const NotificationSectionHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      color: isDark ? AppDarkColors.surface : const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.5),
      child: Text(
        title,
        style: TextStyle(
          fontFamily: 'Helvetica Neue',
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          color: isDark ? AppDarkColors.textSubtitle : const Color(0xFF64748B),
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
