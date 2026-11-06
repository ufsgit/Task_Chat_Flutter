import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/display_mode_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DisplayModeService Tests', () {
    test('enableHighRefreshRate invokes platform method on Android', () async {
      final log = <MethodCall>[];
      const channel = MethodChannel('com.example.task_chat/display_mode');

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        if (methodCall.method == 'enableHighRefreshRate') {
          return 120.0;
        }
        return null;
      });

      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      final rate = await DisplayModeService.enableHighRefreshRate(
        channel: channel,
      );

      expect(rate, equals(120.0));
      expect(log, hasLength(1));
      expect(log.first.method, equals('enableHighRefreshRate'));

      debugDefaultTargetPlatformOverride = null;
    });

    test('enableHighRefreshRate returns null gracefully on non-Android platforms', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final rate = await DisplayModeService.enableHighRefreshRate();

      expect(rate, isNull);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
