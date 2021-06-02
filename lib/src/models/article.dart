import 'word.dart';

class BaseArticle<W extends Word> {
    final List<W> words;

	BaseArticle._(this.words);
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
