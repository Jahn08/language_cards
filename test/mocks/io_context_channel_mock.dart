import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/utilities/io_context_provider.dart';
import 'package:language_cards/src/utilities/path.dart';

class IOContextChannelMock {

	static const String _rootFolderPath = 'test_root';

	IOContextChannelMock._();

	static Future<void> testWithChannel(
		Future<void> Function() action, { bool arePermissionsRequired }
	) async {
		final channel = IOContextProvider.channel;

		try {
			_cleanResources();
			
			channel.setMockMethodCallHandler((call) {
				switch (call.method) {
					case 'isStoragePermissionRequired':
						return Future.value(arePermissionsRequired ?? false);
					case 'getDownloadsDirectoryPath':
						return Future.value(getExternalStoragePath());
					default:
						return Future.value(null);
				}
			});

			await action?.call();
		}
		finally {
			channel.setMockMethodCallHandler(null);
			_cleanResources();
		}
	}

	static String getExternalStoragePath() {
		final path = Path.combine([_rootFolderPath, 'external']);
		final dir = new Directory(path);
		
		if (!dir.existsSync())
			dir.createSync(recursive: true);

		return dir.path;
	}

	static void _cleanResources() {
		final rootDir = Directory(_rootFolderPath);

		if (!rootDir.existsSync())
			return;

		rootDir.deleteSync(recursive: true);
	}
}
