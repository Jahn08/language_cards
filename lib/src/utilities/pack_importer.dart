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

	@override
	String toString() => 
		locale.packImporterImportExceptionContent(importFilePath, error.toString());
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
			
			final packDic = new Map.fromEntries((jsonDecode(file.readAsStringSync()) as List<dynamic>)
				.map<MapEntry<StoredPack, List<StoredWord>>>((pObj) {
					final packWithCardObjs = StoredPack.fromJsonMap(pObj as Map<String, dynamic>);
					return new MapEntry(packWithCardObjs.key, 
						packWithCardObjs.value.map((cObj) => 
							StoredWord.fromDbMap((cObj is String ? jsonDecode(cObj): cObj) as Map<String, dynamic>)).toList());
				}));

			final newPackDic = new Map.fromEntries(
				(await packStorage.upsert(packDic.keys.toList())).map((p) => new MapEntry(p.name, p.id)));
			
			final newCards = packDic.entries.map((e) {
				e.value.forEach((c) { 
					c.packId = newPackDic[e.key.name];
				});
				return e.value;
			}).expand((cards) => cards).toList();
			await cardStorage.upsert(newCards);

			return packDic;
		}
		catch (ex, stackTrace) {
			throw new ImportException(ex, stackTrace, 
				importFilePath: importFilePath, locale: locale);
		}
	}
}
