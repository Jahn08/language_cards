import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/utilities/context_provider.dart';
import 'package:language_cards/src/utilities/path.dart';

class ContextChannelMock {
  static const String _rootFolderPath = 'test_root';

  ContextChannelMock._();

  static Future<void> testWithChannel(Future<void> Function()? action,
      {bool arePermissionsRequired = false}) async {
    const channel = ContextProvider.channel;

    try {
      _cleanResources();

      channel.setMockMethodCallHandler((call) {
        switch (call.method) {
          case 'isStoragePermissionRequired':
            return Future.value(arePermissionsRequired);
          case 'getDownloadsDirectoryPath':
            return Future.value(getExternalStoragePath());
          case 'isEmailHtmlSupported':
            return Future.value(true);
          default:
            return Future.value();
        }
      });

      await action?.call();
    } finally {
      channel.setMockMethodCallHandler(null);
      _cleanResources();
    }
  }

  static String getExternalStoragePath() {
    final path = Path.combine([_rootFolderPath, 'external']);
    final dir = new Directory(path);

    if (!dir.existsSync()) dir.createSync(recursive: true);

    return dir.path;
  }

  static void _cleanResources() {
    final rootDir = Directory(_rootFolderPath);

    if (!rootDir.existsSync()) return;

    rootDir.deleteSync(recursive: true);
  }
}
