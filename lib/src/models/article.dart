import 'package:language_cards/src/models/part_of_speech.dart';
import 'word.dart';

class Article {
    final List<Word> words;

	Article._(this.words);

    Article.fromJson(Map<String, dynamic> json): 
        this._(_decodeWords(json['def'] ?? []));

    static List<Word> _decodeWords(List<dynamic> definitionJson) =>
        definitionJson.map((e) => new Word.fromJson(e)).toList();

	Article mergeWords(Article another) {
		final uniqueWords = another.words.where((w) => !words.contains(w)).toList();
		uniqueWords.addAll(words);

		return new Article._(uniqueWords.fold<List<Word>>(<Word>[], (prev, cur) {
			final equalPosWord = prev.singleWhere((w) => w.partOfSpeech == cur.partOfSpeech, 
				orElse: () => null);
		
			if (equalPosWord == null)
				prev.add(cur);
			else
				equalPosWord.translations.addAll(cur.translations);

			return prev;
		}));
	}

	Article mergeWordTexts(Article source) {
		final wordsByPos = new Map<PartOfSpeech, Word>.fromIterable(source.words, 
			key: (w) => w.partOfSpeech, value: (w) => w);

		return new Article._(words.map((w) {
			final sourceWord = wordsByPos[w.partOfSpeech] ?? wordsByPos.values.first;
			if (sourceWord == null)
				return w;

			return new Word(sourceWord.text, id: w.id, partOfSpeech: w.partOfSpeech, 
				transcription: sourceWord.transcription, translations: w.translations);
		}).toList());
	}
}
