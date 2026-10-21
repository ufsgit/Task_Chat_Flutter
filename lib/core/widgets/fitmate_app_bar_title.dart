import 'package:flutter/material.dart';
import '../theme.dart';

/// Reusable brand widget displaying the Fitmate logo followed by the 'Fitmate' title.
/// Designed for use across all AppBars in the application.
class FitmateAppBarTitle extends StatelessWidget {
  final double logoSize;
  final double spacing;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  const FitmateAppBarTitle({
    super.key,
    this.logoSize = 28,
    this.spacing = 8,
    this.fontSize = 22,
    this.fontWeight = FontWeight.w700,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor = isDark ? Colors.white : AppColors.brandGreen;
    final textColor = color ?? defaultColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/images/fitmate_app_logo.png',
          width: logoSize,
          height: logoSize,
          fit: BoxFit.contain,
        ),
        SizedBox(width: spacing),
        Text(
          'Fitmate',
          style: TextStyle(
            fontFamily: 'Helvetica Neue',
            color: textColor,
            fontSize: fontSize,
            fontWeight: fontWeight,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
