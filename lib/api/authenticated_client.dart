import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/connectivity_service.dart';
import '../login_page/login_view.dart';
import '../login_page/token_storage.dart';
import '../main.dart';
import '../settings/settings_model.dart';
import '../today/today_view_model.dart';

/// An HTTP client interceptor that detects 401 Unauthorized responses.
/// When a 401 occurs on any authenticated endpoint, it wipes the local session
/// and routes the user back to the login screen with a deduplication lock
/// preventing concurrent 401 redirect floods.
class AuthenticatedClient extends http.BaseClient {
  static final AuthenticatedClient instance = AuthenticatedClient();

  static bool _isRedirectingToLogin = false;

  /// Resets the 401 redirect lock (e.g. after a new login or in tests).
  static void resetRedirectLock() {
    _isRedirectingToLogin = false;
  }

  /// Whether a 401 redirect is currently being handled.
  static bool get isRedirectingToLogin => _isRedirectingToLogin;

  http.Client _inner;
  final TokenStorage? tokenStorage;
  final Future<void> Function()? onUnauthorized;

  AuthenticatedClient({
    http.Client? inner,
    this.tokenStorage,
    this.onUnauthorized,
  }) : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    http.StreamedResponse response;
    try {
      response = await _inner.send(request);
      ConnectivityService.instance.reportSuccess();
    } on http.ClientException catch (e) {
      unawaited(ConnectivityService.instance.reportFailure());
      if (e.message.toLowerCase().contains('closed')) {
        _inner = http.Client();
        rethrow;
      }
      rethrow;
    } on TimeoutException {
      unawaited(ConnectivityService.instance.reportFailure());
      rethrow;
    } catch (_) {
      unawaited(ConnectivityService.instance.reportFailure());
      rethrow;
    }

    if (response.statusCode == 401) {
      final isAuthEndpoint = request.url.path.contains('/api/auth');
      if (!isAuthEndpoint) {
        // Fire asynchronously to avoid blocking the HTTP response consumption
        unawaited(_handleUnauthorized());
      }
    }

    return response;
  }

  Future<void> _handleUnauthorized() async {
    if (_isRedirectingToLogin) {
      return;
    }
    _isRedirectingToLogin = true;

    try {
      final storage = tokenStorage ?? TokenStorage();
      await storage.deleteToken();
      await UserProfileData.clear();
      TodayViewModel.resetSession();
    } catch (_) {}

    if (onUnauthorized != null) {
      await onUnauthorized!();
    } else {
      FitmateApp.navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  void close() {
    if (identical(this, instance)) {
      return;
    }
    _inner.close();
  }
}
