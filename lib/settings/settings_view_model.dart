import 'package:flutter/foundation.dart';
import '../login_page/token_storage.dart';
import '../today/today_view_model.dart';
import 'settings_model.dart';

/// ViewModel managing settings business logic, user profile state, and logout actions.
class SettingsViewModel extends ChangeNotifier {
  final TokenStorage _tokenStorage;
  UserProfileData? _profile;
  bool _isLoading = false;

  SettingsViewModel({
    UserProfileData? initialProfile,
    TokenStorage? tokenStorage,
  })  : _profile = initialProfile,
        _tokenStorage = tokenStorage ?? TokenStorage();

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

  /// Clears stored user session from SharedPreferences and deletes auth token on logout.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await UserProfileData.clear();
      await _tokenStorage.deleteToken();
      todayChatItems.clear();
      _profile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
