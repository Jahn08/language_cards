import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import '../data/word_storage.dart';
import '../models/stored_pack.dart';
import '../utilities/path.dart';

class PackExporter {

	static const MethodChannel pathProviderChannel = const MethodChannel('directory_path_provider');

	final WordStorage storage;

	PackExporter(this.storage);

	Future<String> export(List<StoredPack> packs, String filePostfix, AppLocalizations locale) async {
		final packIds = packs.map((p) => p.id).toList();
		final cardsByParent = new Map<int, List<StoredWord>>.fromIterable(packIds,
			key: (id) => id, value: (_) => []);

		(await storage.fetchFiltered(parentIds: packIds))
			.forEach((c) => cardsByParent[c.packId].add(c));

		final contents = jsonEncode(packs.map((p) => p.toJsonMap(cardsByParent[p.id])).toList());
		final dirPath = await _getDownloadDirPath();
		final fileName = 'lang_cards_' + filePostfix;
		File file = new File(_compileFullFileName(dirPath, fileName));

		if ((await _isPermissionRequired()) && !(await Permission.storage.isGranted)) {
			final status = await Permission.storage.request();
			
			if (!status.isGranted)
				throw new Exception(locale.packListScreenExportDialogNoAccessError);
		}

		int postfix = 0;
		while (file.existsSync())
			file = new File(
				_compileFullFileName(dirPath, '${fileName}_${++postfix}'));
	
		file.writeAsStringSync(contents, flush: true);
		return file.path;
	}

	Future<bool> _isPermissionRequired() => pathProviderChannel.invokeMethod('isPermissionRequired');

	Future<String> _getDownloadDirPath() => pathProviderChannel.invokeMethod('getDownloadsDirectoryPath');

	_compileFullFileName(String dirPath, String fileName) => 
		Path.combine([dirPath, fileName + '.json']);
}
