import 'package:flutter/material.dart';

/// Represents a background + icon color pair for circular avatars.
class AvatarColorPair {
  final Color background;
  final Color icon;

  const AvatarColorPair({
    required this.background,
    required this.icon,
  });
}

/// Resolves avatar color pair based on the first letter of the user's name:
/// - PZ share the same colour
/// - AQ share the same colour
/// - BR share the same colour
/// - CS share the same colour
/// - DT share the same colour
/// - EU share the same colour
/// - FV share the same colour
/// - GW share the same colour
/// - HX share the same colour
/// - IY share the same colour
AvatarColorPair getAvatarColorsForName(String? name) {
  if (name == null || name.trim().isEmpty) {
    return const AvatarColorPair(
      background: Color(0xFFFBF0D9),
      icon: Color(0xFF9E6B34),
    );
  }

  final char = name.trim()[0].toUpperCase();

  switch (char) {
    case 'P':
    case 'Z':
      return const AvatarColorPair(
        background: Color(0xFFEDE9FE), // Soft purple
        icon: Color(0xFF7C3AED),
      );
    case 'A':
    case 'Q':
      return const AvatarColorPair(
        background: Color(0xFFE0F2FE), // Sky blue
        icon: Color(0xFF0284C7),
      );
    case 'B':
    case 'R':
      return const AvatarColorPair(
        background: Color(0xFFDCFCE7), // Soft mint green
        icon: Color(0xFF16A34A),
      );
    case 'C':
    case 'S':
      return const AvatarColorPair(
        background: Color(0xFFFEF3C7), // Warm amber
        icon: Color(0xFFD97706),
      );
    case 'D':
    case 'T':
      return const AvatarColorPair(
        background: Color(0xFFFFE4E6), // Soft rose
        icon: Color(0xFFE11D48),
      );
    case 'E':
    case 'U':
      return const AvatarColorPair(
        background: Color(0xFFCCFBF1), // Soft teal
        icon: Color(0xFF0D9488),
      );
    case 'F':
    case 'V':
      return const AvatarColorPair(
        background: Color(0xFFE0E7FF), // Soft indigo
        icon: Color(0xFF4F46E5),
      );
    case 'G':
    case 'W':
      return const AvatarColorPair(
        background: Color(0xFFFFEDD5), // Soft peach orange
        icon: Color(0xFFEA580C),
      );
    case 'H':
    case 'X':
      return const AvatarColorPair(
        background: Color(0xFFFCE7F3), // Soft pink
        icon: Color(0xFFDB2777),
      );
    case 'I':
    case 'Y':
      return const AvatarColorPair(
        background: Color(0xFFECFCCB), // Soft lime
        icon: Color(0xFF65A30D),
      );
    case 'J':
      return const AvatarColorPair(
        background: Color(0xFFE0F2FE),
        icon: Color(0xFF0284C7),
      );
    case 'K':
      return const AvatarColorPair(
        background: Color(0xFFDCFCE7),
        icon: Color(0xFF16A34A),
      );
    case 'L':
      return const AvatarColorPair(
        background: Color(0xFFFEF3C7),
        icon: Color(0xFFD97706),
      );
    case 'M':
      return const AvatarColorPair(
        background: Color(0xFFFFE4E6),
        icon: Color(0xFFE11D48),
      );
    case 'N':
      return const AvatarColorPair(
        background: Color(0xFFCCFBF1),
        icon: Color(0xFF0D9488),
      );
    case 'O':
      return const AvatarColorPair(
        background: Color(0xFFE0E7FF),
        icon: Color(0xFF4F46E5),
      );
    default:
      return const AvatarColorPair(
        background: Color(0xFFFBF0D9),
        icon: Color(0xFF9E6B34),
      );
  }
}

/// Clean circular user avatar with background and icon color resolved by name or explicit parameters.
class UserCircleAvatar extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final String? name;

  const UserCircleAvatar({
    super.key,
    this.size = 48,
    this.backgroundColor,
    this.iconColor,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    final colors = getAvatarColorsForName(name);
    final bg = backgroundColor ?? colors.background;
    final iconCol = iconColor ?? colors.icon;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: size * 0.58,
          color: iconCol,
        ),
      ),
    );
  }
}
