import 'package:language_cards/src/data/data_provider.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/data/study_storage.dart';
import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/models/language.dart';
import 'data_provider_mock.dart';
import 'word_storage_mock.dart';
import '../utilities/randomiser.dart';

class _PackDataProvider extends DataProviderMock<StoredPack> {
  final WordStorageMock wordStorage;

  _PackDataProvider(List<StoredPack> packs, this.wordStorage) : super(packs);

  @override
  StoredPack buildFromDbMap(Map<String, dynamic> map) =>
      new StoredPack.fromDbMap(map);

  @override
  String get indexFieldName => StoredPack.nameFieldName;

  @override
  Future<int> delete(String tableName, List<int> ids) async {
    final deletedCount = await super.delete(tableName, ids);

    await wordStorage.removeFromPacks(ids);
    return deletedCount;
  }
}

class PackStorageMock extends PackStorage with StudyStorage {
  static const int namedPacksNumber = 4;

  final List<StoredPack> _packs;

  final WordStorageMock wordStorage;

  @override
  WordStorage buildWordStorage() => wordStorage;

  @override
  DataProvider get connection => new _PackDataProvider(_packs, wordStorage);

  PackStorageMock(
      {int packsNumber,
      int cardsNumber,
      String Function(String, int) textGetter})
      : _packs = _generatePacks(packsNumber ?? namedPacksNumber,
            textGetter: textGetter),
        wordStorage = new WordStorageMock(
            cardsNumber: cardsNumber,
            parentsOverall: packsNumber ?? namedPacksNumber,
            textGetter: textGetter);

  static void _sort(List<StoredPack> packs) =>
      packs.sort((a, b) => a.isNone ? -1 : a.name.compareTo(b.name));

  static List<StoredPack> _generatePacks(int packsNumber,
      {String Function(String, int) textGetter}) {
    final packs = new List<StoredPack>.generate(
        packsNumber, (index) => generatePack(index + 1, textGetter));
    _sort(packs);

    return packs;
  }

  static StoredPack generatePack(
      [int id, String Function(String, int) textGetter]) {
    final text = Randomiser.nextString();
    return new StoredPack(textGetter?.call(text, id) ?? text,
        id: id,
        from: Language.english,
        to: Language.russian,
        studyDate: id.isEven
            ? DateTime.now().add(new Duration(days: -Randomiser.nextInt(99)))
            : null,
        cardsNumber: 0);
  }

  StoredPack getRandom() =>
      Randomiser.nextElement(_packs.where((p) => !p.isNone).toList());
}
