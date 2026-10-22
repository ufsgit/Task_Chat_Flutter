import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../login_page/login_model.dart';

/// Data model representing the user's profile on the Settings screen.
class UserProfileData {
  static const _prefKey = 'auth_user_profile';

  final String name;
  final String initials;
  final String phone;
  final String? email;
  final String? stateName;
  final String? districtName;
  final bool isOnline;

  const UserProfileData({
    required this.name,
    required this.initials,
    required this.phone,
    this.email,
    this.stateName,
    this.districtName,
    this.isOnline = true,
  });

  /// Persists the logged-in user to SharedPreferences.
  static Future<void> save(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 1));
      await prefs.setString(_prefKey, jsonEncode(user.toJson()));
    } catch (_) {}
  }

  /// Loads the persisted user profile from SharedPreferences.
  static Future<UserProfileData?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 1));
      final raw = prefs.getString(_prefKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfileData.fromUserModel(UserModel.fromJson(map));
    } catch (_) {
      return null;
    }
  }

  /// Loads the persisted UserModel from SharedPreferences.
  static Future<UserModel?> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 1));
      final raw = prefs.getString(_prefKey);
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserModel.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Clears stored user session from SharedPreferences on logout.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance()
          .timeout(const Duration(seconds: 1));
      await prefs.remove(_prefKey);
    } catch (_) {}
  }

  factory UserProfileData.fromUserModel(UserModel user) {
    return UserProfileData(
      name: user.name.isNotEmpty ? user.name : user.username,
      initials: computeInitials(user.name.isNotEmpty ? user.name : user.username),
      phone: user.phone ?? '',
      email: user.email,
      stateName: user.stateName,
      districtName: user.districtName,
      isOnline: user.isActive == 1,
    );
  }

  static String computeInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      final s = parts[0];
      return s.isNotEmpty
          ? (s.length >= 2 ? s.substring(0, 2).toUpperCase() : s.toUpperCase())
          : '';
    }
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  UserProfileData copyWith({
    String? name,
    String? initials,
    String? phone,
    String? email,
    String? stateName,
    String? districtName,
    bool? isOnline,
  }) {
    return UserProfileData(
      name: name ?? this.name,
      initials: initials ?? this.initials,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      stateName: stateName ?? this.stateName,
      districtName: districtName ?? this.districtName,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

