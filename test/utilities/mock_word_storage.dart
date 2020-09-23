import 'package:language_cards/src/data/base_storage.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/models/word.dart';
import 'package:language_cards/src/widgets/english_phonetic_keyboard.dart';
import './mock_pack_storage.dart';
import './randomiser.dart';

class MockWordStorage implements BaseStorage<StoredWord> {
    final List<StoredWord> _words = _generateWords(15);

    MockWordStorage() {
        _sortWords();
    }

    _sortWords() => _words.sort((a, b) => a.text.compareTo(b.text));

    Future<List<StoredWord>> fetch({ int parentId, int skipCount, int takeCount }) {
        return Future.delayed(new Duration(milliseconds: 100),
            () => _fetch(parentId).skip(skipCount ?? 0).take(takeCount ?? 10).toList());
    }

    Iterable<StoredWord> _fetch([int parentId]) => parentId == null ? _words : 
        _words.where((w) => w.packId == parentId);

    Future<int> getLength({ int parentId }) {
        return Future.delayed(new Duration(milliseconds: 100), () => _fetch(parentId).length);
    }

    Future<bool> save(StoredWord word) async {
        if (word.id > 0)
            _words.removeWhere((w) => w.id == word.id);
        else
            word.id = _words.length;

        _words.add(word);
        _sortWords();
        
        return Future.value(true);
    }

    Future<StoredWord> find(int id) =>
        Future.value(id > 0 ? _words.firstWhere((w) => w.id == id, orElse: () => null) : null);

    static List<StoredWord> _generateWords(int length) {
        const phoneticSymbols = EnglishPhoneticKeyboard.PHONETIC_SYMBOLS;
        return new List<StoredWord>.generate(length, (index) {
            return new StoredWord(Randomiser.nextString(), 
                id: index + 1, 
                partOfSpeech: Word.PARTS_OF_SPEECH[Randomiser.nextInt(Word.PARTS_OF_SPEECH.length)],
                translation: new List<String>.generate(Randomiser.nextInt(5) + 1, 
                    (index) => Randomiser.nextString()).join('; '),
                transcription: new List<String>.generate(Randomiser.nextInt(7) + 1, 
                    (_) => Randomiser.nextElement(phoneticSymbols)).join(),
                packId: Randomiser.nextInt(MockPackStorage.packNumber) + 1
            );
        });
    }

    Future<void> remove(Iterable<int> ids) {
        _words.removeWhere((w) => ids.contains(w.id));
        return Future.value();
    }

    StoredWord getRandom() => Randomiser.nextElement(_words);
}
