import 'dart:io';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:language_cards/src/utilities/string_ext.dart';

class FakePathProviderPlatform extends PathProviderPlatform {

	static const String _rootFolderPath = 'test_root';

	FakePathProviderPlatform._();

	static testWithinPathProviderContext(Future<void> Function() tester) async {
		FakePathProviderPlatform instance;
		try {
			instance = new FakePathProviderPlatform._();
			PathProviderPlatform.instance = instance;

			await tester?.call();
		}
		finally {
			instance?.dispose();
		}
	}

	@override
	Future<String> getExternalStoragePath() {
		final path = joinPaths([_rootFolderPath, 'external']);
		final dir = new Directory(path);
		
		if (!dir.existsSync())
			dir.createSync(recursive: true);

		return Future.value(dir.path);
	} 

	dispose() {
		final rootDir = Directory(_rootFolderPath);

		if (!rootDir.existsSync())
			return;

		rootDir.deleteSync(recursive: true);
	}
}
