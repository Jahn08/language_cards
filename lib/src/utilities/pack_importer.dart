import 'dart:convert';
import 'dart:io';
import 'string_ext.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';

class ImportException {
	
	final String importFilePath;

	final StackTrace trace;

	final Error error;

	ImportException(this.importFilePath, this.error, this.trace);

	toString() => 'A failure while reading an import file "$importFilePath": ${error.toString()}; ' +
		'stack trace: ${trace.toString()}';
}

class PackImporter {

	final BaseStorage<StoredPack> packStorage;
	
	final BaseStorage<StoredWord> cardStorage;
	
	PackImporter(this.packStorage, this.cardStorage);

	Future<Map<StoredPack, List<StoredWord>>> import(String importFilePath) async {
		try {
			if (isNullOrEmpty(importFilePath))
				return null;

			final file = new File(importFilePath);

			if (!file.existsSync())
				return null;

			final packObjs = jsonDecode(file.readAsStringSync()) as List<dynamic>;
			final importedPackedCards = <StoredPack, List<StoredWord>>{};
			for (final pObj in packObjs) {
				final packWithCardObjs = StoredPack.fromJsonMap(pObj);
				final newPack = (await packStorage.upsert([packWithCardObjs.key])).first;

				final cards = packWithCardObjs.value.map((cObj) { 
					final card = StoredWord.fromDbMap(jsonDecode(cObj));
					card.packId = newPack.id;
					return card;
				}).toList();

				await cardStorage.upsert(cards);
				importedPackedCards[newPack] = cards;
			}

			return importedPackedCards;
		}
		catch (ex, stackTrace) {
			throw new ImportException(importFilePath, ex, stackTrace);
		}
	}
}
