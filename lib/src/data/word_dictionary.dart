import 'dart:convert' show jsonDecode;
import 'package:meta/meta.dart';
import 'package:http/http.dart';
import '../models/article.dart';
import '../models/language.dart';

class WordDictionary {
    final String _uri;
    final Client _client;

    WordDictionary(String apiKey, { @required Language from, Language to, Client client }): 
        _uri = _buildFullUri(apiKey, from, to),
        _client = client ?? new Client();

    static String _buildFullUri(String key, Language from, [Language to]) {
        final _from = _representLanguage(from);
        final _to = _representLanguage(to ?? from);
        return 'https://dictionary.yandex.net/api/v1/dicservice.json/lookup?key=$key&lang=$_from-$_to';
    }

    static String _representLanguage(Language lang) =>
        lang == Language.russian ? 'ru': 'en';

    Future<Article> lookUp(String word) async {
        final response = await _client.post(_uri + '&text=$word');
        return new Article.fromJson(jsonDecode(response.body));
    }

    dispose() {
        _client?.close();
    }
}
