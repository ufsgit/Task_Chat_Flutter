import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../login_page/login_view.dart';
import '../login_page/token_storage.dart';
import '../main.dart';
import '../settings/settings_model.dart';
import '../today/today_view_model.dart';

/// An HTTP client interceptor that detects 401 Unauthorized responses.
/// When a 401 occurs on any authenticated endpoint, it wipes the local session
/// and routes the user back to the login screen.
class AuthenticatedClient extends http.BaseClient {
  static final AuthenticatedClient instance = AuthenticatedClient();

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
    } on http.ClientException catch (e) {
      if (e.message.toLowerCase().contains('closed')) {
        _inner = http.Client();
        // Re-create request if needed or resend
        // If request is a streamed request that has already been finalized, it may not be resendable.
        // But for future requests, _inner is renewed.
        rethrow;
      }
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
