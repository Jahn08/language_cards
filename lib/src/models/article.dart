import 'word.dart';

class BaseArticle<W extends Word> {
    final List<W> words;

	BaseArticle._(this.words);
}

class Article extends BaseArticle<Word> {

	Article._(List<Word> words): super._(words);

    Article.fromJson(Map<String, dynamic> json): 
        this._(_decodeWords(json['def'] as List<dynamic> ?? []));

	static List<Word> _decodeWords(List<dynamic> definitionJson) =>
        definitionJson.map((e) => new Word.fromJson(e as Map<String, dynamic>)).toList();
}

class AssetArticle extends BaseArticle<AssetWord> {

	AssetArticle._(List<AssetWord> words): super._(words);

    AssetArticle(String text, List<Map<String, dynamic>> words): 
		this._(_decodeWords(text, words));

	static List<AssetWord> _decodeWords(String text, List<Map<String, dynamic>> definitionJson) =>
        (definitionJson ?? []).map((e) => new AssetWord.fromJson(text, e)).toList();
}
