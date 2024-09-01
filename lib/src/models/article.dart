import 'word.dart';

class BaseArticle<W extends Word> {
  final List<W> words;

  const BaseArticle._(this.words);
}

class Article extends BaseArticle<Word> {
  const Article._(List<Word> words) : super._(words);

  Article.fromJson(Map<String, dynamic> json)
      : this._(_decodeWords(json['def'] as List<dynamic> ?? []));

  static List<Word> _decodeWords(List<dynamic> definitionJson) => definitionJson
      .map((e) => new Word.fromJson(e as Map<String, dynamic>))
      .toList();
}

class AssetArticle extends BaseArticle<AssetWord> {
  AssetArticle(String text, List<Map<String, dynamic>> words)
      : this._(_decodeWords(text, words));

  const AssetArticle._(List<AssetWord> words) : super._(words);

  static List<AssetWord> _decodeWords(
          String text, List<Map<String, dynamic>> definitionJson) =>
      (definitionJson ?? [])
          .map((e) => new AssetWord.fromJson(text, e))
          .toList();
}
