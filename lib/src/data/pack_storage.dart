import 'dart:math';
import '../data/base_storage.dart';
import '../data/word_storage.dart';
import '../models/language.dart';
import '../models/stored_pack.dart';

export '../models/stored_pack.dart';

class PackStorage implements BaseStorage<StoredPack> {
    final List<StoredPack> _packs = _generatePacks(5);

    static PackStorage _storage;

    PackStorage._();

    static PackStorage get instance => _storage == null ? 
        (_storage = new PackStorage._()) : _storage;

    static void _sort(List<StoredPack> packs) => 
        packs.sort((a, b) => a.name.compareTo(b.name));

    Future<List<StoredPack>> fetch({ int parentId, int skipCount, int takeCount }) {
        return Future.delayed(
            new Duration(milliseconds: new Random().nextInt(1000)),
                () async {
                    final wordStorage = WordStorage.instance;
                    final futurePacks = _packs.skip(skipCount ?? 0).take(takeCount ?? 10)
                        .map((p) async {
                            final wordsNumber = (await wordStorage.getLength(parentId: p.id));
                            return new StoredPack.copy(p, cardsNumber: wordsNumber);
                        });
                    return Future.wait<StoredPack>(futurePacks);
                });
    }

    Future<bool> save(List<StoredPack> words) async {
        words.forEach((word) { 
            if (word.id > 0)
                _packs.removeWhere((w) => w.id == word.id);
            else
                word.id = _packs.length + 1;

            _packs.add(word);
        });
        _sort(_packs);
        
        return Future.value(true);
    }

    Future<StoredPack> find(int id) async {
        if (id <= 0)
            return null;

        final pack = _packs.firstWhere((w) => w.id == id, orElse: () => null);
        final wordsNumber = await WordStorage.instance.getLength(parentId: pack.id);
        return new StoredPack.copy(pack, cardsNumber: wordsNumber);
    }

    // TODO: A temporary method to debug rendering a list of word decks
    static List<StoredPack> _generatePacks(int length) {
        final generatedPacks = List<StoredPack>.generate(length, (index) {
            final random = new Random();
            return new StoredPack(random.nextDouble().toString(), 
                id: index + 1, 
                from: Language.english,
                to: Language.russian
            );
        });
        _sort(generatedPacks);

        final packs = <StoredPack>[StoredPack.none];
        packs.addAll(generatedPacks);

        return packs;
    }

    Future<void> remove(Iterable<int> ids) {
        _packs.removeWhere((w) => ids.contains(w.id));
        return Future.value();
    }
}
