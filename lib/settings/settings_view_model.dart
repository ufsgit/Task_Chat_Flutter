import 'package:flutter/foundation.dart';
import 'settings_model.dart';

/// ViewModel managing settings business logic, user profile state, and logout actions.
class SettingsViewModel extends ChangeNotifier {
  UserProfileData? _profile;
  bool _isLoading = false;

  SettingsViewModel({UserProfileData? initialProfile})
      : _profile = initialProfile;

  UserProfileData? get profile => _profile;
  bool get isLoading => _isLoading;

  /// Returns non-null profile or empty profile (no default/hardcoded values).
  UserProfileData get activeProfile =>
      _profile ??
      const UserProfileData(
        name: '',
        initials: '',
        phone: '',
      );

  void setProfile(UserProfileData profile) {
    _profile = profile;
    notifyListeners();
  }

  /// Loads cached user profile from SharedPreferences.
  Future<void> loadProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      final cached = await UserProfileData.load();
      if (cached != null) {
        _profile = cached;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears stored user session from SharedPreferences on logout.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await UserProfileData.clear();
      _profile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
