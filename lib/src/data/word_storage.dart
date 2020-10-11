import 'dart:math';
import '../data/base_storage.dart';
import '../models/stored_word.dart';
import '../models/word.dart';
import '../models/word_study_stage.dart';
import '../widgets/english_phonetic_keyboard.dart';

export '../models/stored_word.dart';
export '../data/base_storage.dart';

class WordStorage implements BaseStorage<StoredWord> {
    final List<StoredWord> _words = _generateWords(15);

    static WordStorage _storage;

    WordStorage._() {
        _sortWords();
    }

    static WordStorage get instance => _storage == null ? (_storage = new WordStorage._()) : _storage;

    _sortWords() => _words.sort((a, b) => a.text.compareTo(b.text));

    Future<List<StoredWord>> fetch({ int parentId, int skipCount, int takeCount }) {
        return Future.delayed(
            new Duration(milliseconds: new Random().nextInt(1000)),
                () => _fetch(parentId).skip(skipCount ?? 0).take(takeCount ?? 10).toList());
    }

    Iterable<StoredWord> _fetch([int parentId]) => parentId == null ? _words : 
        _words.where((w) => w.packId == parentId);

    Future<int> getLength({ int parentId }) {
        return Future.delayed(
            new Duration(milliseconds: new Random().nextInt(1000)),
                () => _fetch(parentId).length);
    }

    Future<bool> save(StoredWord word) async {
        if (word.isNew)
            word.id = _words.length + 1;
        else
            _words.removeWhere((w) => w.id == word.id);

        _words.add(word);
        _sortWords();
        
        return Future.value(true);
    }

    Future<StoredWord> find(int id) =>
        Future.value(id > 0 ? _words.firstWhere((w) => w.id == id, orElse: () => null) : null);

    // TODO: A temporary method to debug rendering a list of words
    static List<StoredWord> _generateWords(int length) {
        const phoneticSymbols = EnglishPhoneticKeyboard.PHONETIC_SYMBOLS;
        
        const studyStages = WordStudyStage.values;
        final studyStagesLength = studyStages.length;

        return new List<StoredWord>.generate(length, (index) {
            final random = new Random();
            return new StoredWord(random.nextDouble().toString(), 
                id: index + 1, 
                partOfSpeech: _getRandomListElement(Word.PARTS_OF_SPEECH, random),
                translation: new List<String>.generate(random.nextInt(5) + 1, 
                    (index) => random.nextDouble().toString()).join('; '),
                transcription: new List<String>.generate(random.nextInt(7) + 1, 
                    (_) => _getRandomListElement(phoneticSymbols, random)).join(),
                packId: random.nextInt(5) + 1,
                studyProgress: studyStages[random.nextInt(studyStagesLength)]
            );
        });
    }

    static T _getRandomListElement<T>(List<T> list, Random random) => 
        list[random.nextInt(list.length)];

    Future<void> remove(Iterable<int> ids) {
        _words.removeWhere((w) => ids.contains(w.id));
        return Future.value();
    }
}
