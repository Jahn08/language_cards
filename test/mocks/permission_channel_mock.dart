import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class PermissionChannelMock {
  static const _channel =
      MethodChannel('flutter.baseflow.com/permissions/methods');

  PermissionChannelMock._();

  static Future<void> testWithChannel(Future<void> Function() action,
      {bool noPermissionsByDefault = false,
      bool shouldDenyPermissions = false}) async {
    try {
      _channel.setMockMethodCallHandler((call) {
        switch (call.method) {
          case 'checkPermissionStatus':
            return Future.value(noPermissionsByDefault ? 0 : 1);
          case 'requestPermissions':
            return Future.value({15: (shouldDenyPermissions ? 0 : 1)});
          default:
            return Future.value();
        }
      });

      await action.call();
    } finally {
      _channel.setMockMethodCallHandler(null);
    }
  }
}
