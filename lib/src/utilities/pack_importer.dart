import 'dart:convert';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'string_ext.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';

class ImportException implements Exception {
  final String importFilePath;

  final StackTrace trace;

  final Object error;

  final AppLocalizations locale;

  const ImportException(this.error, this.trace,
      {required this.locale, required this.importFilePath});

  @override
  String toString() => locale.packImporterImportExceptionContent(
      importFilePath, error.toString());
}

class PackImporter {
  final BaseStorage<StoredPack> packStorage;

  final BaseStorage<StoredWord> cardStorage;

  final AppLocalizations locale;

  const PackImporter(this.packStorage, this.cardStorage, this.locale);

  Future<Map<StoredPack, List<StoredWord>>> import(
      String importFilePath) async {
    try {
      if (isNullOrEmpty(importFilePath))
        throw new FileSystemException(locale
            .packListScreenImportDialogFileNotFoundContent(importFilePath));

      final file = new File(importFilePath);
      if (!file.existsSync())
        throw new FileSystemException(
            locale
                .packListScreenImportDialogFileNotFoundContent(importFilePath),
            importFilePath);

      final packDic = new Map.fromEntries(
          (jsonDecode(file.readAsStringSync()) as List<dynamic>)
              .map<MapEntry<StoredPack, List<StoredWord>>>((pObj) {
        final packWithCardObjs =
            StoredPack.fromJsonMap(pObj as Map<String, dynamic>);
        return new MapEntry(
            packWithCardObjs.key,
            packWithCardObjs.value
                .map((cObj) => StoredWord.fromDbMap((cObj is String
                    ? jsonDecode(cObj)
                    : cObj) as Map<String, dynamic>))
                .toList());
      }));

      await packStorage.upsert(packDic.keys.toList());

      final newCards = packDic.entries
          .map((e) {
            final packId = e.key.id;
            e.value.forEach((c) {
              c.packId = packId;
            });
            return e.value;
          })
          .expand((cards) => cards)
          .toList();
      await cardStorage.upsert(newCards);

      return packDic;
    } catch (ex, stackTrace) {
      throw new ImportException(ex, stackTrace,
          importFilePath: importFilePath, locale: locale);
    }
  }
}
