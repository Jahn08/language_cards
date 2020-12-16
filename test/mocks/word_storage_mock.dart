import 'package:language_cards/src/data/base_storage.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/models/word.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/widgets/english_phonetic_keyboard.dart';
import 'pack_storage_mock.dart';
import '../utilities/randomiser.dart';

class WordStorageMock extends BaseStorage<StoredWord> {
    final List<StoredWord> _words = _generateWords(18);

    WordStorageMock() {
        _sortWords();
    }

    _sortWords() => _words.sort((a, b) => a.text.compareTo(b.text));

    Future<List<StoredWord>> fetch({ List<int> parentIds, int skipCount, int takeCount }) {
        return Future.delayed(new Duration(milliseconds: 25),
            () => _fetch(parentIds).skip(skipCount ?? 0).take(takeCount ?? 10).toList());
    }

    Iterable<StoredWord> _fetch([List<int> parentIds]) => parentIds == null ? _words : 
        _words.where((w) => parentIds.contains(w.packId));

    Future<int> groupByParent(List<int> parentIds) {
        return Future.delayed(new Duration(milliseconds: 50), () => _fetch(parentIds).length);
    }

    Future<StoredWord> find(int id) =>
        Future.value(id > 0 ? _words.firstWhere((w) => w.id == id, orElse: () => null) : null);

    static List<StoredWord> _generateWords(int length) {
        final cardsWithoutPackNumber = Randomiser.nextInt(3) + 1;
        final cardsWithPackNumber = length - cardsWithoutPackNumber;
        final words = new List<StoredWord>.generate(cardsWithPackNumber, 
            (index) => generateWord(id: index + 1));
        words.addAll(new List<StoredWord>.generate(cardsWithoutPackNumber,
            (index) => generateWord(id: cardsWithPackNumber + index + 1, packId: 0)));

        return words;
    }

    static StoredWord generateWord({ int id, int packId }) {
        const phoneticSymbols = EnglishPhoneticKeyboard.PHONETIC_SYMBOLS;

        const studyStages = WordStudyStage.values;
        return new StoredWord(Randomiser.nextString(), 
            id: id, 
            partOfSpeech: Word.PARTS_OF_SPEECH[Randomiser.nextInt(Word.PARTS_OF_SPEECH.length)],
            translation: new List<String>.generate(Randomiser.nextInt(5) + 1, 
                (index) => Randomiser.nextString()).join('; '),
            transcription: new List<String>.generate(Randomiser.nextInt(7) + 1, 
                (_) => Randomiser.nextElement(phoneticSymbols)).join(),
            packId: packId ?? Randomiser.nextInt(PackStorageMock.packNumber) + 1,
            studyProgress: Randomiser.nextElement(studyStages)
        );
    }

    Future<void> delete(List<int> ids) {
        _words.removeWhere((w) => ids.contains(w.id));
        return Future.value();
    }

    StoredWord getRandom() => Randomiser.nextElement(_words);

    @override
    String get entityName => '';
  
    @override
    Future<void> update(List<StoredWord> words) => _save(words);

    Future<List<StoredWord>> _save(List<StoredWord> words) async {
        words.forEach((word) { 
            if (word.id > 0)
                _words.removeWhere((w) => w.id == word.id);
            else
                word.id = _words.length;

            _words.add(word);
        });

        _sortWords();
        return words;
    }

    Future<void> updateWordProgress(int id, int studyProgress) async {
        final wordToUpdate = _words.firstWhere((w) => w.id == id, orElse: null);
        
        if (wordToUpdate == null)
            return;

        await upsert(new StoredWord(wordToUpdate.text,
            id:  wordToUpdate.id,
            packId:  wordToUpdate.packId,
            studyProgress: studyProgress,
            partOfSpeech: wordToUpdate.partOfSpeech,
            transcription: wordToUpdate.transcription,
            translation: wordToUpdate.translation
        ));
    }

    @override
    Future<StoredWord> upsert(StoredWord word) async => 
        (await _save([word])).first;

    @override
    List<StoredWord> convertToEntity(List<Map<String, dynamic>> values) {
        throw UnimplementedError();
    }

    Future<Map<int, Map<int, int>>> groupByStudyLevels() {
        return Future.value(_words.fold<Map<int, Map<int, int>>>({},
            (res, w) {
                final packId = w.packId;
                if (!res.containsKey(packId))
                    res[packId] = new Map<int, int>();

                if (res[packId].containsKey(w.studyProgress))
                    res[packId][w.studyProgress] += 1;
                else
                    res[packId][w.studyProgress] = 1;

                return res;
            }));
    }
}
