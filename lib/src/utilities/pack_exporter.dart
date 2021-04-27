import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data/word_storage.dart';
import '../models/stored_pack.dart';
import '../utilities/path.dart';

class PackExporter {

	final WordStorage storage;

	PackExporter(this.storage);

	Future<String> export(List<StoredPack> packs, String filePostfix) async {
		final packIds = packs.map((p) => p.id).toList();
		final cardsByParent = new Map<int, List<StoredWord>>.fromIterable(packIds,
			key: (id) => id, value: (_) => []);

		(await storage.fetchFiltered(parentIds: packIds))
			.forEach((c) => cardsByParent[c.packId].add(c));

		final contents = jsonEncode(packs.map((p) => p.toJsonMap(cardsByParent[p.id])).toList());
		final dir = await getExternalStorageDirectory();
	
		final fileName = 'lang_cards_' + filePostfix;
		File file = new File(_compileFullFileName(dir.path, fileName));

		int postfix = 0;
		while (file.existsSync())
			file = new File(
				_compileFullFileName(dir.path, '${fileName}_${++postfix}'));
	
		file.writeAsStringSync(contents, flush: true);
		return file.path;
	}

	_compileFullFileName(String dirPath, String fileName) => 
		Path.combine([dirPath, fileName + '.json']);
}
