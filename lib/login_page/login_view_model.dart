import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:task_chat/login_page/token_storage.dart';
import '../api/api.dart';
import '../core/connectivity_service.dart';
import '../services/notification_service.dart';
import 'login_model.dart';

/// ViewModel managing login business logic, API communication, and state.
class LoginViewModel extends ChangeNotifier {
  final http.Client _client;
  final bool _isInternalClient;
  final TokenStorage _tokenStorage;

  bool _isLoading = false;
  String? _errorMessage;

  LoginViewModel({http.Client? client, TokenStorage? tokenStorage})
    : _client = client ?? http.Client(),
      _isInternalClient = client == null,
      _tokenStorage = tokenStorage ?? TokenStorage();

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
      final response = await _client
          .post(
            Uri.parse(ApiConfig.mobileLogin),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(
              LoginRequest(
                username: cleanUsername,
                password: cleanPassword,
              ).toJson(),
            ),
          )
          .timeout(const Duration(seconds: 10));

      Map<String, dynamic> data = {};
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            data = decoded;
          }
        } catch (_) {
          // Response body was not JSON (e.g. HTML or plain text server error page)
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token =
            data['sessionToken']?.toString() ??
            data['token']?.toString() ??
            data['access_token']?.toString();

        await _tokenStorage.savetoken(token ?? "");

        // Step 2: Immediately register device FCM token with backend
        if (token != null && token.isNotEmpty) {
          unawaited(
            NotificationService.registerDeviceWithBackend(jwtToken: token),
          );
        }

        final userMap = data['user'] is Map<String, dynamic>
            ? data['user'] as Map<String, dynamic>
            : data;

        final user = UserModel.fromJson(userMap);
        final isCoordinator = user.isCoordinator;

        _isLoading = false;
        notifyListeners();
        ConnectivityService.instance.reportSuccess();
        return LoginResult.success(
          token: token,
          user: user,
          isCoordinator: isCoordinator,
        );
      } else {
        final friendlyMsg = _formatErrorMessage(response.statusCode, data);
        _errorMessage = friendlyMsg;
        _isLoading = false;
        notifyListeners();
        return LoginResult.failure(friendlyMsg);
      }
    } on SocketException {
      ConnectivityService.instance.reportFailure();
      const errorMsg = 'Connection failed. Please check your network.';
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return LoginResult.failure(errorMsg);
    } on TimeoutException {
      ConnectivityService.instance.reportFailure();
      const errorMsg = 'Connection failed. Please check your network.';
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return LoginResult.failure(errorMsg);
    } on http.ClientException {
      ConnectivityService.instance.reportFailure();
      const errorMsg = 'Connection failed. Please check your network.';
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return LoginResult.failure(errorMsg);
    } catch (_) {
      ConnectivityService.instance.reportFailure();
      const errorMsg = 'Connection failed. Please check your network.';
      _errorMessage = errorMsg;
      _isLoading = false;
      notifyListeners();
      return LoginResult.failure(errorMsg);
    }
  }

  /// Converts raw server errors and status codes into clear, user-friendly messages.
  static String _formatErrorMessage(int statusCode, dynamic data) {
    String? rawMessage;
    if (data is Map) {
      final val = data['message'] ?? data['error'] ?? data['detail'];
      if (val != null) {
        rawMessage = val.toString().trim();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      rawMessage = data.trim();
    }

    // 5xx Server errors
    if (statusCode >= 500) {
      return 'Our server is temporarily unavailable. Please try again shortly.';
    }

    if (rawMessage != null && rawMessage.isNotEmpty) {
      final lower = rawMessage.toLowerCase();

      // Check for technical/developer details: "(role 2 or 3)" or "unauthorized for mobile login"
      if (lower.contains('role') ||
          lower.contains('not authorized for mobile')) {
        return 'Incorrect username or password, or your account is not authorized for mobile access.';
      }

      // Deactivated or locked accounts
      if (lower.contains('deactivat') ||
          lower.contains('inactive') ||
          lower.contains('suspend') ||
          lower.contains('lock') ||
          lower.contains('disabled')) {
        return 'Your account is deactivated. Please contact your administrator.';
      }

      // Invalid credentials
      if (lower.contains('invalid credential') ||
          lower.contains('invalid login') ||
          lower.contains('wrong password') ||
          lower.contains('user not found') ||
          lower.contains('incorrect password') ||
          lower.contains('bad credentials')) {
        return 'Incorrect username or password. Please try again.';
      }

      // Rate limit
      if (lower.contains('too many') || lower.contains('rate limit')) {
        return 'Too many login attempts. Please wait a moment and try again.';
      }

      // Filter out technical leaks like SQL syntax, exceptions, stack traces
      final hasTechnicalJargon =
          lower.contains('exception') ||
          lower.contains('sql') ||
          lower.contains('null pointer') ||
          lower.contains('syntax') ||
          lower.contains('econnrefused') ||
          lower.contains('stack trace');

      if (!hasTechnicalJargon) {
        final clean = rawMessage[0].toUpperCase() + rawMessage.substring(1);
        return clean.endsWith('.') ? clean : '$clean.';
      }
    }

    // Fallbacks based on status code
    switch (statusCode) {
      case 401:
        return 'Incorrect username or password. Please try again.';
      case 403:
        return 'You do not have permission to log in. Please contact your administrator.';
      case 404:
        return 'Account not found. Please check your credentials and try again.';
      case 429:
        return 'Too many login attempts. Please wait a moment and try again.';
      default:
        return 'Unable to log in. Please check your credentials and try again.';
    }
  }

  @override
  void dispose() {
    if (_isInternalClient) {
      _client.close();
    }
    super.dispose();
  }
}
