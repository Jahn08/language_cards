import 'part_of_speech.dart';
import 'word.dart';

class BaseArticle<W extends Word> {
    final List<W> words;

	BaseArticle._(this.words);

	BaseArticle<W> mergeWords(BaseArticle<W> another) {
		final uniqueWords = another.words.where((w) => !words.contains(w)).toList();
		uniqueWords.addAll(words);

		return new BaseArticle._(uniqueWords.fold<List<W>>(<W>[], (prev, cur) {
			final equalPosWord = prev.singleWhere((w) => w.partOfSpeech == cur.partOfSpeech, 
				orElse: () => null);
		
			if (equalPosWord == null)
				prev.add(cur);
			else
				equalPosWord.translations.addAll(cur.translations);

			return prev;
		}));
	}

	BaseArticle<W> mergeWordTexts(BaseArticle<W> source) {
		final wordsByPos = new Map<PartOfSpeech, W>.fromIterable(source.words, 
			key: (w) => w.partOfSpeech, value: (w) => w);

		return new BaseArticle._(words.map((w) {
			final sourceWord = wordsByPos[w.partOfSpeech] ?? wordsByPos.values.first;
			if (sourceWord == null)
				return w;

			return new Word(sourceWord.text, id: w.id, partOfSpeech: w.partOfSpeech, 
				transcription: sourceWord.transcription, translations: w.translations);
		}).toList());
	}
}

class Article extends BaseArticle<Word> {

	Article._(List<Word> words): super._(words);

    Article.fromJson(Map<String, dynamic> json): 
        this._(_decodeWords(json['def'] ?? []));

	static List<Word> _decodeWords(List<dynamic> definitionJson) =>
        definitionJson.map((e) => new Word.fromJson(e)).toList();
}

class AssetArticle extends BaseArticle<AssetWord> {

	AssetArticle._(List<AssetWord> words): super._(words);

    AssetArticle(String text, List<dynamic> words): this._(_decodeWords(text, words));

	static List<AssetWord> _decodeWords(String text, List<dynamic> definitionJson) =>
        (definitionJson ?? []).map((e) => new AssetWord.fromJson(text, e)).toList();
}
