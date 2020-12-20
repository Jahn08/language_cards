import 'package:language_cards/src/data/base_storage.dart';
import 'package:language_cards/src/data/study_storage.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/language.dart';
import 'word_storage_mock.dart';
import '../utilities/randomiser.dart';

class PackStorageMock extends BaseStorage<StoredPack> with StudyStorage {
    static const int packNumber = 4;

    final List<StoredPack> _packs = _generatePacks(packNumber);

    final WordStorageMock wordStorage = new WordStorageMock();

    PackStorageMock();

    static void _sort(List<StoredPack> packs) => 
        packs.sort((a, b) => a.name.compareTo(b.name));

    @override
    Future<List<StoredPack>> fetch({ List<int> parentIds, int skipCount, int takeCount }) =>
        _fetchInternally(skipCount: skipCount, takeCount: takeCount ?? 10);

    Future<List<StoredPack>> _fetchInternally({ int skipCount, int takeCount }) {
        return Future.delayed(new Duration(milliseconds: 50),
            () async {
                var futurePacks = _packs.skip(skipCount ?? 0);
                
                if (takeCount != null && takeCount > 0)
                    futurePacks = futurePacks.take(takeCount);

                return Future.wait<StoredPack>(futurePacks.map((p) async {
                    p.cardsNumber = (await this.wordStorage.groupByParent([p.id]))[p.id];
                    return p;
                }));
            });
    }

    Future<StoredPack> find(int id) async {
        if (id < 0)
            return null;

        final pack = _packs.firstWhere((w) => w.id == id, orElse: () => null);
        final cardNumberGroups = await this.wordStorage.groupByParent([pack.id]);
        pack.cardsNumber = cardNumberGroups[pack.id];

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

    @override
    Future<List<StudyPack>> fetchStudyPacks() async {
        final packs = await _fetchInternally();
        final packMap = new Map<int, StoredPack>.fromIterable(packs, 
            key: (p) => p.id, value: (p) => p);
        
        return (await wordStorage.groupByStudyLevels())
            .entries.where((e) => e.key > 0)
            .map((e) => new StudyPack(packMap[e.key], e.value)).toList();
    }
}
