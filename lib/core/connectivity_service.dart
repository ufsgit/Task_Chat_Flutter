import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Centralized service to monitor and broadcast global internet connectivity state.
///
/// Designed to be passive when online (no periodic polling), and active only
/// when an API call fails due to no internet—polling DNS every 10 seconds
/// until connectivity is restored.
class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();

  /// Flag to indicate test environments to avoid real platform calls or DNS lookups.
  static bool isTestEnvironment = false;

  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _recoveryTimer;
  bool _isChecking = false;

  ConnectivityService._internal();

  /// Initializes connectivity listeners without running any background periodic timer.
  Future<void> initialize() async {
    if (isTestEnvironment || kIsWeb) return;

    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChanged(results);
    });
  }

  void _handleConnectivityChanged(List<ConnectivityResult> results) {
    if (results.isEmpty ||
        results.every((r) => r == ConnectivityResult.none)) {
      // OS says no network interface is active
      reportFailure();
    } else if (!isConnected.value) {
      // Network interface came back while we were marked offline; check if internet works
      checkConnection();
    }
  }

  /// Verifies active internet reachability using DNS lookup.
  Future<bool> checkConnection() async {
    if (isTestEnvironment) return isConnected.value;
    if (_isChecking) return isConnected.value;

    _isChecking = true;
    bool reachable = false;
    try {
      final lookup = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(seconds: 3));
      reachable = lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      try {
        final fallback = await InternetAddress.lookup('one.one.one.one')
            .timeout(const Duration(seconds: 3));
        reachable = fallback.isNotEmpty && fallback.first.rawAddress.isNotEmpty;
      } catch (_) {
        reachable = false;
      }
    } finally {
      _isChecking = false;
    }

    if (reachable) {
      reportSuccess();
    } else {
      _updateStatus(false);
    }

    return reachable;
  }

  /// Called when an API call fails due to no internet.
  /// Shows the global banner and starts checking DNS every 10 seconds.
  void reportFailure() {
    _updateStatus(false);
    _startRecoveryPolling();
  }

  /// Called when an API call succeeds or DNS check confirms internet is back.
  /// Stops the 10-second timer and restores connected status.
  void reportSuccess() {
    _stopRecoveryPolling();
    _updateStatus(true);
  }

  /// Starts checking every 10 seconds to detect when internet is restored.
  void _startRecoveryPolling() {
    if (isTestEnvironment) return;
    if (_recoveryTimer != null && _recoveryTimer!.isActive) return;

    debugPrint('>>> [ConnectivityService] Started 10s recovery polling');
    _recoveryTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final restored = await checkConnection();
      if (restored) {
        _stopRecoveryPolling();
      }
    });
  }

  /// Cancels the 10-second recovery polling timer.
  void _stopRecoveryPolling() {
    if (_recoveryTimer != null) {
      debugPrint('>>> [ConnectivityService] Stopped 10s recovery polling');
      _recoveryTimer?.cancel();
      _recoveryTimer = null;
    }
  }

  /// Manually update connected status (used in tests or manual overrides).
  void setConnected(bool value) {
    if (value) {
      reportSuccess();
    } else {
      reportFailure();
    }
  }

  void _updateStatus(bool value) {
    if (isConnected.value != value) {
      isConnected.value = value;
      debugPrint('>>> [ConnectivityService] Internet status changed: $value');
    }
  }

  void dispose() {
    _subscription?.cancel();
    _stopRecoveryPolling();
  }
}
