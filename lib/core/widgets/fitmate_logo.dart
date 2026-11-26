import 'package:flutter/material.dart';

/// Reusable brand logo widget for Fitmate.
class FitmateLogo extends StatelessWidget {
  final double size;

  const FitmateLogo({
    super.key,
    this.size = 104,
  });

  @override
  Widget build(BuildContext context) {
    final scale = size / 104.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(26 * scale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
            blurRadius: 20 * scale,
            offset: Offset(0, 8 * scale),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26 * scale),
        child: Image.asset(
          'assets/images/fitmate_logo.jpg',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
