import 'package:language_cards/src/data/base_storage.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/language.dart';
import './mock_word_storage.dart';
import './randomiser.dart';

class MockPackStorage extends BaseStorage<StoredPack> {
    static const int packNumber = 4;

    final List<StoredPack> _packs = _generatePacks(packNumber);

    final MockWordStorage wordStorage = new MockWordStorage();

    MockPackStorage();

    static void _sort(List<StoredPack> packs) => 
        packs.sort((a, b) => a.name.compareTo(b.name));

    @override
    Future<List<StoredPack>> fetch({ List<int> parentIds, int skipCount, int takeCount }) {
        return Future.delayed(
            new Duration(milliseconds: 50),
                () async {
                    final futurePacks = _packs.skip(skipCount ?? 0).take(takeCount ?? 10)
                        .map((p) async {
                            p.cardsNumber = (await this.wordStorage.groupByParent([p.id]));
                            return p;
                        });

                    return Future.wait<StoredPack>(futurePacks);
                });
    }

    Future<StoredPack> find(int id) async {
        if (id < 0)
            return null;

        final pack = _packs.firstWhere((w) => w.id == id, orElse: () => null);
        final cardsNumber = await this.wordStorage.groupByParent([pack.id]);
        pack.cardsNumber = cardsNumber;

        return pack;
    }

    static List<StoredPack> _generatePacks(int length) {
        final generatedPacks = new List<StoredPack>.generate(length, 
            (index) => generatePack(index + 1));
        _sort(generatedPacks);

        final packs = <StoredPack>[StoredPack.none];
        packs.addAll(generatedPacks);

        return packs;
    }

    static StoredPack generatePack([int id]) => 
        new StoredPack(Randomiser.nextString(), 
            id: id ?? 0, 
            from: Language.english,
            to: Language.russian
        );

    @override
    Future<void> delete(List<int> ids) {
        _packs.removeWhere((w) => ids.contains(w.id));
        return Future.value();
    }

    StoredPack getRandom() => Randomiser.nextElement(_packs);

    @override
    List<StoredPack> convertToEntity(List<Map<String, dynamic>> values) {
        throw UnimplementedError();
    }

    @override
    String get entityName => '';

    @override
    Future<void> update(List<StoredPack> packs) => _save(packs);
  
    Future<List<StoredPack>> _save(List<StoredPack> packs) async {
        packs.forEach((pack) {
            if (pack.id > 0)
                _packs.removeWhere((w) => w.id == pack.id);
            else
                pack.id = _packs.length + 1;

            _packs.add(pack);
        });

        _sort(_packs);
        return packs;
    }

    @override
    Future<StoredPack> upsert(StoredPack pack) async => 
        (await _save([pack])).first;
}
