import 'package:flutter/material.dart';

/// Clean circular user avatar with a soft cream background and warm brown person icon,
/// matching the app design system and replacing text initials.
class UserCircleAvatar extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const UserCircleAvatar({
    super.key,
    this.size = 48,
    this.backgroundColor = const Color(0xFFFBF0D9),
    this.iconColor = const Color(0xFF9E6B34),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.58,
          color: iconColor,
        ),
      ),
    );
  }
}
