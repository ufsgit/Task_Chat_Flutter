/// Data model representing the user's profile on the Settings screen.
class UserProfileData {
  final String name;
  final String initials;
  final String phone;
  final bool isVerified;
  final bool isOnline;

  const UserProfileData({
    required this.name,
    required this.initials,
    required this.phone,
    this.isVerified = true,
    this.isOnline = true,
  });

  UserProfileData copyWith({
    String? name,
    String? initials,
    String? phone,
    bool? isVerified,
    bool? isOnline,
  }) {
    return UserProfileData(
      name: name ?? this.name,
      initials: initials ?? this.initials,
      phone: phone ?? this.phone,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}

/// Default / Mock profile data for Rajesh Sharma.
/// Separating this makes it easy to hook into authentication/API later.
const UserProfileData defaultUserProfile = UserProfileData(
  name: 'Rajesh Sharma',
  initials: 'RS',
  phone: '+91 98765 43210',
  isVerified: true,
  isOnline: true,
);
