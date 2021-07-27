import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/utilities/pack_exporter.dart';
import 'package:language_cards/src/utilities/path.dart';

class PathProviderChannelMock {

	static const String _rootFolderPath = 'test_root';

	PathProviderChannelMock._();

	static Future<void> testWithChannel(
		Future<void> Function() action, { bool arePermissionsRequired }
	) async {
		try {
			_cleanResources();
			
			PackExporter.pathProviderChannel.setMockMethodCallHandler((call) {
				switch (call.method) {
					case 'isPermissionRequired':
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
			PackExporter.pathProviderChannel.setMockMethodCallHandler(null);
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
