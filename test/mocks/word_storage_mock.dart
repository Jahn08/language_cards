import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/models/word.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/widgets/english_phonetic_keyboard.dart';
import 'pack_storage_mock.dart';
import '../utilities/randomiser.dart';

class WordStorageMock extends WordStorage {
    final List<StoredWord> _words = _generateWords(18);

    WordStorageMock() {
        _sortWords();
    }

    _sortWords() => _words.sort((a, b) => a.text.compareTo(b.text));

    @override
    Future<List<StoredWord>> fetchFiltered({ List<int> parentIds, List<int> studyStageIds,
        String text, int skipCount, int takeCount }) {
        return Future.delayed(new Duration(milliseconds: 25),
            () => _fetch(parentIds: parentIds, text: text, 
				skipCount: skipCount, takeCount: takeCount));
    }

    @override
    Future<List<StoredWord>> fetch({ String textFilter, int skipCount, int takeCount }) {
        return Future.delayed(new Duration(milliseconds: 25),
            () => _fetch(skipCount: skipCount, text: textFilter, takeCount: takeCount));
    }

    List<StoredWord> _fetch({ List<int> parentIds, String text, int skipCount, int takeCount }) {
        var values = (parentIds == null ? _words : 
            _words.where((w) => parentIds.contains(w.packId)));

		if (text != null && text.isNotEmpty)
			values = values.where((w) => w.text.startsWith(text));
		
		values = values.skip(skipCount ?? 0);
        return ((takeCount ?? 0) == 0 ? values: values.take(takeCount)).toList();
    }

    @override
    Future<Map<int, int>> groupByParent(List<int> parentIds) {
        return Future.delayed(new Duration(milliseconds: 50), 
            () {
                final cards = _fetch(parentIds: parentIds);
                return new Map<int, int>.fromIterable(parentIds, key: (id) => id,
                    value: (id) => cards.where((c) => c.packId == id).length);
            });
    }

    Future<StoredWord> find(int id) =>
        Future.value(id == null ? null: _words.firstWhere((w) => w.id == id, orElse: () => null));

    static List<StoredWord> _generateWords(int length) {
        final cardsWithoutPackNumber = Randomiser.nextInt(3) + 1;
        final cardsWithPackNumber = length - cardsWithoutPackNumber;
        final words = new List<StoredWord>.generate(cardsWithPackNumber, 
            (index) => generateWord(id: index + 1));
        words.addAll(new List<StoredWord>.generate(cardsWithoutPackNumber,
            (index) => generateWord(id: cardsWithPackNumber + index + 1, hasNoPack: true)));

        return words;
    }

    static StoredWord generateWord({ int id, int packId, bool hasNoPack = false }) {
        const phoneticSymbols = EnglishPhoneticKeyboard.phonetic_symbols;

        const studyStages = WordStudyStage.values;
        return new StoredWord(Randomiser.nextString(), 
            id: id, 
            partOfSpeech: Word.parts_of_speech[Randomiser.nextInt(Word.parts_of_speech.length)],
            translation: new List<String>.generate(Randomiser.nextInt(5) + 1, 
                (index) => Randomiser.nextString()).join('; '),
            transcription: new List<String>.generate(Randomiser.nextInt(5) + 5, 
                (_) => Randomiser.nextElement(phoneticSymbols)).join(),
            packId: hasNoPack ? null: packId ?? Randomiser.nextInt(PackStorageMock.namedPacksNumber) + 1,
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

    Future<List<StoredWord>> _save(List<StoredWord> words) {
        words.forEach((word) { 
            if (word.id == null)
                word.id = _words.length;
            else
				_words.removeWhere((w) => w.id == word.id);

            _words.add(word);
        });

        _sortWords();
        return Future.value(words);
    }

    Future<StoredWord> updateWordProgress(int id, int studyProgress) async {
        final wordToUpdate = _words.firstWhere((w) => w.id == id, orElse: null);
        
        if (wordToUpdate == null)
            return null;

        return upsert(new StoredWord(wordToUpdate.text,
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

	@override
	Future<Map<String, int>> groupByTextIndex([Map<String, List<dynamic>> groupValues]) =>
		groupByTextIndexAndParent();

	@override
	Future<Map<String, int>> groupByTextIndexAndParent([List<int> parentIds]) => 
		Future.value(_fetch(parentIds: parentIds).fold<Map<String, int>>({}, (res, c) {
			final index = c.text[0].toUpperCase();
			res[index] = (res[index] ?? 0) + 1;

			return res;
		}));
}
