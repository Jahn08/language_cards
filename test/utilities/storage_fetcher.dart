import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/stored_word.dart';
import '../mocks/pack_storage_mock.dart';
import '../mocks/word_storage_mock.dart';

class StorageFetcher {
  StorageFetcher._();

  static Future<List<StoredPack>> fetchNamedPacks(PackStorageMock storage,
          {LanguagePair? langPair}) async =>
      (await storage.fetch(languagePair: langPair))
          .where((p) => !p.isNone)
          .toList();

  static Future<List<StoredWord>> fetchPackedCards(
          List<StoredPack> packs, WordStorageMock wordStorage) =>
      wordStorage.fetchFiltered(parentIds: packs.map((p) => p.id).toList());
}
