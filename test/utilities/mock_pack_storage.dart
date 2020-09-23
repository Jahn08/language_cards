import 'package:language_cards/src/data/base_storage.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/language.dart';
import './mock_word_storage.dart';
import './randomiser.dart';

class MockPackStorage implements BaseStorage<StoredPack> {
    static const int packNumber = 4;

    final List<StoredPack> _packs = _generatePacks(packNumber);

    final MockWordStorage wordStorage = new MockWordStorage();

    MockPackStorage() {
        _sort();
    }

    _sort() => _packs.sort((a, b) => a.name.compareTo(b.name));

    Future<List<StoredPack>> fetch({ int parentId, int skipCount, int takeCount }) {
        return Future.delayed(
            new Duration(milliseconds: 100),
                () async {
                    final futurePacks = _packs.skip(skipCount ?? 0).take(takeCount ?? 10)
                        .map((p) async {
                            final wordsNumber = (await this.wordStorage.getLength(parentId: p.id));
                            return new StoredPack.copy(p, cardsNumber: wordsNumber);
                        });
                    return Future.wait<StoredPack>(futurePacks);
                });
    }

    Future<bool> save(StoredPack word) async {
        if (word.id > 0)
            _packs.removeWhere((w) => w.id == word.id);
        else
            word.id = _packs.length + 1;

        _packs.add(word);
        _sort();
        
        return Future.value(true);
    }

    Future<StoredPack> find(int id) async {
        if (id <= 0)
            return null;

        final pack = _packs.firstWhere((w) => w.id == id, orElse: () => null);
        final wordsNumber = await this.wordStorage.getLength(parentId: pack.id);
        return new StoredPack.copy(pack, cardsNumber: wordsNumber);
    }

    // TODO: A temporary method to debug rendering a list of word decks
    static List<StoredPack> _generatePacks(int length) {
        return new List<StoredPack>.generate(length, (index) {
            return new StoredPack(Randomiser.nextString(), 
                id: index + 1, 
                from: Language.english,
                to: Language.russian
            );
        });
    }

    Future<void> remove(Iterable<int> ids) {
        _packs.removeWhere((w) => ids.contains(w.id));
        return Future.value();
    }

    StoredPack getRandom() => Randomiser.nextElement(_packs);
}
