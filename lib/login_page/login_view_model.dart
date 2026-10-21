import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../api/api.dart';
import 'login_model.dart';

/// ViewModel managing login business logic, API communication, and state.
class LoginViewModel extends ChangeNotifier {
  final http.Client _client;

  bool _isLoading = false;
  String? _errorMessage;

  LoginViewModel({http.Client? client}) : _client = client ?? http.Client();

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<LoginResult> login({
    required String username,
    required String password,
  }) async {
    final cleanUsername = username.trim();
    final cleanPassword = password;

    if (cleanUsername.isEmpty || cleanPassword.isEmpty) {
      _errorMessage = 'Please enter both username and password';
      notifyListeners();
      return LoginResult.failure(_errorMessage!);
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _client.post(
        Uri.parse(ApiConfig.mobileLogin),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
          LoginRequest(
            username: cleanUsername,
            password: cleanPassword,
          ).toJson(),
        ),
      );

      final Map<String, dynamic> data = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token =
            data['sessionToken']?.toString() ??
            data['token']?.toString() ??
            data['access_token']?.toString();

        final userMap = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;

        final user = UserModel.fromJson(userMap);
        final isCoordinator = user.isCoordinator;

        _isLoading = false;
        notifyListeners();
        return LoginResult.success(
          token: token,
          user: user,
          isCoordinator: isCoordinator,
        );
      } else {
        _errorMessage = "Invalid login";
        _isLoading = false;
        notifyListeners();
        return LoginResult.failure("Invalid login");
      }
    } catch (_) {
      const errorMsg = 'Network error';
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return LoginResult.failure("Invalid login");
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
