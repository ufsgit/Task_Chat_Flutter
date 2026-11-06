import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service to configure and ensure 120Hz high refresh rate display mode on supported devices.
class DisplayModeService {
  DisplayModeService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.task_chat/display_mode');

  /// Requests the highest available refresh rate (e.g. 120Hz / 90Hz) from the native platform.
  /// Returns the configured refresh rate in Hz, or null if unsupported.
  static Future<double?> enableHighRefreshRate({
    MethodChannel? channel,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }
    try {
      final methodChannel = channel ?? _channel;
      final rate = await methodChannel.invokeMethod<double>('enableHighRefreshRate');
      debugPrint('>>> [DisplayModeService] High refresh rate active: ${rate}Hz');
      return rate;
    } catch (e) {
      debugPrint('>>> [DisplayModeService] Note: $e');
      return null;
    }
  }
}

