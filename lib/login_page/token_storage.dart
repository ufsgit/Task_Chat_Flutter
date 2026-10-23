import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static final Map<String, String> _memoryCache = {};
  static bool useMemoryOnly = false;

  /// Safely checks if the code is executing in a unit or widget test runner.
  /// Prevents UnsupportedError: Platform._environment on Android and iOS.
  static bool get isTestEnvironment {
    if (useMemoryOnly) return true;
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid || Platform.isIOS) return false;
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  final FlutterSecureStorage _storage;
  static const String _primaryKey = 'access_token';
  static const String _legacyKey = 'access-token';

  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  Future<void> savetoken(String token) async {
    _memoryCache[_primaryKey] = token;
    _memoryCache[_legacyKey] = token;
    if (useMemoryOnly) return;
    try {
      await _storage.write(key: _primaryKey, value: token);
      await _storage.write(key: _legacyKey, value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    if (useMemoryOnly) {
      return _memoryCache[_primaryKey] ?? _memoryCache[_legacyKey];
    }
    try {
      final token = await _storage.read(key: _primaryKey);
      if (token != null && token.isNotEmpty) {
        return token;
      }
      final legacy = await _storage.read(key: _legacyKey);
      if (legacy != null && legacy.isNotEmpty) {
        return legacy;
      }
    } catch (_) {}
    return _memoryCache[_primaryKey] ?? _memoryCache[_legacyKey];
  }

  Future<void> deleteToken() async {
    _memoryCache.remove(_primaryKey);
    _memoryCache.remove(_legacyKey);
    if (useMemoryOnly) return;
    try {
      await _storage.delete(key: _primaryKey);
      await _storage.delete(key: _legacyKey);
    } catch (_) {}
  }
}
