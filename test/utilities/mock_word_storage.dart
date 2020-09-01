import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/models/word.dart';
import 'package:language_cards/src/widgets/english_phonetic_keyboard.dart';
import './randomiser.dart';

class MockWordStorage implements IWordStorage {
    final List<StoredWord> _words = _generateWords(15);

    MockWordStorage() {
        _sortWords();
    }

    _sortWords() => _words.sort((a, b) => a.text.compareTo(b.text));

    Future<List<StoredWord>> fetch({ int skipCount, int takeCount }) {
        return Future.delayed(
            new Duration(milliseconds: Randomiser.buildRandomInt(1000)),
                () => _words.skip(skipCount ?? 0).take(takeCount ?? 10).toList());
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
            return new StoredWord(Randomiser.buildRandomString(), 
                id: index + 1, 
                partOfSpeech: Word.PARTS_OF_SPEECH[Randomiser.buildRandomInt(Word.PARTS_OF_SPEECH.length)],
                translation: new List<String>.generate(Randomiser.buildRandomInt(5) + 1, 
                    (index) => Randomiser.buildRandomString()).join('; '),
                transcription: new List<String>.generate(Randomiser.buildRandomInt(7) + 1, 
                    (_) => Randomiser.getRandomElement(phoneticSymbols)).join()
            );
        });
    }

    Future<void> remove(Iterable<int> ids) {
        _words.removeWhere((w) => ids.contains(w.id));
        return Future.value();
    }

    StoredWord getRandomWord() => Randomiser.getRandomElement(_words);
}
