import 'dart:collection';
import 'package:language_cards/src/data/data_provider.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/data/study_storage.dart';
import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/models/language.dart';
import 'data_provider_mock.dart';
import 'word_storage_mock.dart';
import '../utilities/randomiser.dart';

class _PackDataProvider extends DataProviderMock<StoredPack> {
  HashSet<String>? _intFieldNames;

  final WordStorageMock wordStorage;

  _PackDataProvider(super.packs, this.wordStorage);

  @override
  StoredPack buildFromDbMap(Map<String, dynamic> map) =>
      new StoredPack.fromDbMap(map);

  @override
  String get indexFieldName => StoredPack.nameFieldName;

  @override
  Future<int> delete(String tableName, List<int?> ids) async {
    final deletedCount = await super.delete(tableName, ids);

    await wordStorage.removeFromPacks(ids);
    return deletedCount;
  }

  @override
  HashSet<String> get intFieldNames => _intFieldNames ??= super.intFieldNames
    ..addAll([StoredPack.fromFieldName, StoredPack.toFieldName]);
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
      {int? packsNumber,
      int? cardsNumber,
      String Function(String, int?)? textGetter,
      bool singleLanguagePair = true})
      : _packs = _generatePacks(packsNumber ?? namedPacksNumber,
            textGetter: textGetter, singleLanguagePair: singleLanguagePair),
        wordStorage = new WordStorageMock(
            cardsNumber: cardsNumber,
            parentsOverall: packsNumber ?? namedPacksNumber,
            textGetter: textGetter);

  static void _sort(List<StoredPack> packs) =>
      packs.sort((a, b) => a.isNone ? -1 : a.name.compareTo(b.name));

  static List<StoredPack> _generatePacks(int packsNumber,
      {String Function(String, int?)? textGetter,
      bool singleLanguagePair = true}) {
    final packs = new List<StoredPack>.generate(packsNumber,
        (index) => generatePack(index + 1, textGetter, singleLanguagePair));
    _sort(packs);

    return packs;
  }

  static StoredPack generatePack(
      [int? id,
      String Function(String, int?)? textGetter,
      bool singleLanguagePair = true]) {
    final text = Randomiser.nextString();
    final isIdEven = id?.isEven == true;
    return new StoredPack(textGetter?.call(text, id) ?? text,
        id: id,
        from: Language.english,
        to: singleLanguagePair || isIdEven
            ? Language.russian
            : Language.spanish,
        studyDate: isIdEven
            ? DateTime.now().add(new Duration(days: -Randomiser.nextInt(99)))
            : null,
        cardsNumber: 0);
  }

  StoredPack getRandom() =>
      Randomiser.nextElement(_packs.where((p) => !p.isNone).toList());
}
