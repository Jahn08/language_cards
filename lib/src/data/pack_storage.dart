import 'dart:math';
import '../data/base_storage.dart';
import '../models/language.dart';
import '../models/stored_pack.dart';

export '../models/stored_pack.dart';

class PackStorage implements BaseStorage<StoredPack> {
    final List<StoredPack> _decks = _generateDecks(5);

    static PackStorage _storage;

    PackStorage._() {
        _sort();
    }

    static PackStorage get instance => _storage == null ? 
        (_storage = new PackStorage._()) : _storage;

    _sort() => _decks.sort((a, b) => a.name.compareTo(b.name));

    Future<List<StoredPack>> fetch({ int parentId, int skipCount, int takeCount }) {
        return Future.delayed(
            new Duration(milliseconds: new Random().nextInt(1000)),
                () => _decks.skip(skipCount ?? 0).take(takeCount ?? 10).toList());
    }

    Future<bool> save(StoredPack word) async {
        if (word.id > 0)
            _decks.removeWhere((w) => w.id == word.id);
        else
            word.id = _decks.length + 1;

        _decks.add(word);
        _sort();
        
        return Future.value(true);
    }

    Future<StoredPack> find(int id) =>
        Future.value(id > 0 ? _decks.firstWhere((w) => w.id == id, orElse: () => null) : null);

    // TODO: A temporary method to debug rendering a list of word decks
    static List<StoredPack> _generateDecks(int length) {
        return new List<StoredPack>.generate(length, (index) {
            final random = new Random();
            return new StoredPack(random.nextDouble().toString(), 
                id: index + 1, 
                from: Language.english,
                to: Language.russian
            );
        });
    }

    Future<void> remove(Iterable<int> ids) {
        _decks.removeWhere((w) => ids.contains(w.id));
        return Future.value();
    }
}
