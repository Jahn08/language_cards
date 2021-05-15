import 'dart:convert';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'string_ext.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';

class ImportException implements Exception {
	
	final String importFilePath;

	final StackTrace trace;

	final Object error;

	final AppLocalizations locale;

	ImportException(this.error, this.trace, {
		@required this.locale, @required this.importFilePath
	});

	toString() => locale.packImporterImportExceptionContent(importFilePath, error.toString());
}

class PackImporter {

	final BaseStorage<StoredPack> packStorage;
	
	final BaseStorage<StoredWord> cardStorage;

	final AppLocalizations locale;
	
	PackImporter(this.packStorage, this.cardStorage, this.locale);

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
			throw new ImportException(ex, stackTrace, 
				importFilePath: importFilePath, locale: locale);
		}
	}
}
