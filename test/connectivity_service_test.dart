import 'package:flutter_test/flutter_test.dart';
import 'package:task_chat/core/connectivity_service.dart';

void main() {
  setUp(() {
    ConnectivityService.isTestEnvironment = true;
    ConnectivityService.instance.setConnected(true);
  });

  tearDown(() {
    ConnectivityService.instance.setConnected(true);
  });

  test('ConnectivityService initializes with connected true', () {
    expect(ConnectivityService.instance.isConnected.value, isTrue);
  });

  test('reportFailure marks connectivity offline', () {
    ConnectivityService.instance.reportFailure();
    expect(ConnectivityService.instance.isConnected.value, isFalse);
  });

  test('reportSuccess marks connectivity online', () {
    ConnectivityService.instance.reportFailure();
    expect(ConnectivityService.instance.isConnected.value, isFalse);

    ConnectivityService.instance.reportSuccess();
    expect(ConnectivityService.instance.isConnected.value, isTrue);
  });

  test('checkConnection in test mode respects current connection state', () async {
    ConnectivityService.instance.reportFailure();
    final result = await ConnectivityService.instance.checkConnection();
    expect(result, isFalse);

    ConnectivityService.instance.reportSuccess();
    final resultOnline = await ConnectivityService.instance.checkConnection();
    expect(resultOnline, isTrue);
  });
}

