import './word.dart';

class Article {
    final List<Word> words;

    Article.fromJson(Map<String, dynamic> json): 
        words = _decodeWords(json['def'] ?? []);

    static List<Word> _decodeWords(List<dynamic> definitionJson) =>
        definitionJson.map((e) => new Word.fromJson(e)).toList();
}
