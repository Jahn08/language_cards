import 'package:language_cards/src/data/base_storage.dart';
import 'package:language_cards/src/data/study_storage.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/language.dart';
import 'word_storage_mock.dart';
import '../utilities/randomiser.dart';

class PackStorageMock extends BaseStorage<StoredPack> with StudyStorage {
    static const int namedPacksNumber = 4;

    final List<StoredPack> _packs = _generatePacks();

    final WordStorageMock wordStorage = new WordStorageMock();

    PackStorageMock();

    static void _sort(List<StoredPack> packs) => 
        packs.sort((a, b) => a.isNone ? -1: a.name.compareTo(b.name));

    @override
    Future<List<StoredPack>> fetch({ String textFilter, int skipCount, int takeCount }) =>
        _fetchInternally(nameFilter: textFilter, skipCount: skipCount, takeCount: takeCount);

    Future<List<StoredPack>> _fetchInternally({ String nameFilter, int skipCount, int takeCount }) {
        return Future.delayed(new Duration(milliseconds: 50),
            () async {
                var futurePacks = _packs.skip(skipCount ?? 0);
                
                if (takeCount != null && takeCount > 0)
                    futurePacks = futurePacks.take(takeCount);
						
				if (nameFilter != null && nameFilter.isNotEmpty)
					futurePacks = futurePacks.where((p) => p.name.startsWith(nameFilter));

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

    static List<StoredPack> _generatePacks() {
        final packs = <StoredPack>[StoredPack.none];
        packs.addAll(new List<StoredPack>.generate(namedPacksNumber, 
            (index) => generatePack(index + 1)));
        _sort(packs);

        return packs;
    }

    static StoredPack generatePack([int id]) => 
        new StoredPack(Randomiser.nextString(), 
            id: id ?? 0, 
            from: Language.english,
            to: Language.russian,
			cardsNumber: 0
        );

    @override
    Future<void> delete(List<int> ids) {
        _packs.removeWhere((w) => ids.contains(w.id));
        return Future.value();
    }

    StoredPack getRandom() => 
		Randomiser.nextElement(_packs.where((p) => !p.isNone).toList());

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

	@override
	String get textFilterFieldName => throw UnimplementedError();

	@override
	Future<Map<String, int>> groupByTextIndex([Map<String, List<dynamic>> groupValues]) =>
		Future.value(_packs.fold<Map<String, int>>({}, (res, p) {
			if (!p.isNone) {
				final index = p.name[0].toUpperCase();
				res[index] = (res[index] ?? 0) + 1;
			}
			
			return res;
		}));
}
