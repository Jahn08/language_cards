import 'dart:collection';
import 'package:language_cards/src/data/data_provider.dart';
import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/models/part_of_speech.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/widgets/phonetic_keyboard.dart';
import 'data_provider_mock.dart';
import 'pack_storage_mock.dart';
import '../utilities/randomiser.dart';

class _WordDataProvider extends DataProviderMock<StoredWord> {

	HashSet<String> _intFieldNames;

	_WordDataProvider(List<StoredWord> cards): super(cards);

	@override
	StoredWord buildFromDbMap(Map<String, dynamic> map) => 
		new StoredWord.fromDbMap(map);
		
	@override
	String get indexFieldName => StoredWord.textFieldName;
	
	@override
	HashSet<String> get intFieldNames => 
		_intFieldNames ??= super.intFieldNames..addAll([StoredWord.packIdFieldName, StoredWord.studyProgressFieldName]);
}

class WordStorageMock extends WordStorage {
	final List<StoredWord> _words;

    WordStorageMock({ 
		int cardsNumber, int parentsOverall, String Function(String, int) textGetter 
	}): _words = _generateWords(cardsNumber ?? 18, parentsOverall, textGetter: textGetter) { 
		_sortWords(); 
	}

    void _sortWords() => _words.sort((a, b) => a.text.compareTo(b.text));

	@override
	DataProvider get connection => new _WordDataProvider(_words);

    static List<StoredWord> _generateWords(int length, int parentsOverall, 
		{ String Function(String, int) textGetter }) {
        final cardsWithoutPackNumber = Randomiser.nextInt(4) + 1;
        final cardsWithPackNumber = length - cardsWithoutPackNumber;
        final words = new List<StoredWord>.generate(cardsWithPackNumber, 
            (index) => generateWord(
				id: index + 1, 
				packId: parentsOverall == null ? null: 
					(index < parentsOverall ? index: index % parentsOverall) + 1,
				textGetter: textGetter
			));
        words.addAll(new List<StoredWord>.generate(cardsWithoutPackNumber,
            (index) => generateWord(id: cardsWithPackNumber + index + 1, hasNoPack: true,
				textGetter: textGetter)));

        return words;
    }

    static StoredWord generateWord({ 
		int id, int packId, int parentsOverall, bool hasNoPack = false,
		String Function(String, int) textGetter 
	}) {
        final phoneticSymbols = PhoneticKeyboard.getLanguageSpecific((_) => _).symbols;

        const studyStages = WordStudyStage.values;
		final text = Randomiser.nextString();
        return new StoredWord(textGetter?.call(text, id) ?? text, 
            id: id, 
            partOfSpeech: Randomiser.nextElement(PartOfSpeech.values),
            translation: new List<String>.generate(Randomiser.nextInt(5) + 1, 
                (index) => Randomiser.nextString()).join('; '),
            transcription: new List<String>.generate(Randomiser.nextInt(5) + 5, 
                (_) => Randomiser.nextElement(phoneticSymbols)).join(),
            packId: hasNoPack ? null: packId ?? 
				Randomiser.nextInt(parentsOverall ?? PackStorageMock.namedPacksNumber) + 1,
            studyProgress: Randomiser.nextElement(studyStages)
        );
    }

    StoredWord getRandom() => Randomiser.nextElement(_words);

    Future<StoredWord> updateWordProgress(int id, int studyProgress) async {
        final wordToUpdate = _words.firstWhere((w) => w.id == id, orElse: () => null);
        
        if (wordToUpdate == null)
            return null;

        final cards = await upsert([new StoredWord(wordToUpdate.text,
            id:  wordToUpdate.id,
            packId:  wordToUpdate.packId,
            studyProgress: studyProgress,
            partOfSpeech: wordToUpdate.partOfSpeech,
            transcription: wordToUpdate.transcription,
            translation: wordToUpdate.translation
        )]);

		return cards.first;
    }

	Future<void> removeFromPacks(List<int> packIds) async {
		final cards = await fetchFiltered(parentIds: packIds);
		final untiedCards = cards.map((c) {
			final values = c.toDbMap();
			values[StoredWord.packIdFieldName] = null;

			return new StoredWord.fromDbMap(values);
		}).toList();
		await upsert(untiedCards);
	}
}
