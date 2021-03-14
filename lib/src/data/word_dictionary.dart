import 'dart:convert' show jsonDecode;
import 'package:meta/meta.dart';
import 'package:http/http.dart';
import '../models/article.dart';
import '../models/language.dart';

class WordDictionary {
    final Uri _uri;
    final Client _client;

    WordDictionary(String apiKey, { @required Language from, Language to, Client client }): 
        _uri = _buildFullUri(apiKey, from, to),
        _client = client ?? new Client();

    static Uri _buildFullUri(String key, Language from, [Language to]) {
        final _from = _representLanguage(from);
        final _to = _representLanguage(to ?? from);
        return new Uri(
			host: 'dictionary.yandex.net', 
			pathSegments: ['api', 'v1', 'dicservice.json', 'lookup'],
			queryParameters: {
				'key': key,
				'lang': '$_from-$_to'
			}
		);
    }

    static String _representLanguage(Language lang) =>
        lang == Language.russian ? 'ru': 'en';

    Future<Article> lookUp(String word) async {
		final params = new Map<String, dynamic>.of(_uri.queryParameters);
		params['text'] = word;

        final response = await _client.post(Uri.https(_uri.authority, _uri.path, params));
        return new Article.fromJson(jsonDecode(response.body));
    }

    dispose() {
        _client?.close();
    }
}
