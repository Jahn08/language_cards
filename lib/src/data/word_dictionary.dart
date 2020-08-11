import 'dart:convert' show jsonDecode;
import 'package:http/http.dart';
import '../models/article.dart';

class WordDictionary {
    final String _uri;
    final Client _client;

    WordDictionary(String apiKey, { Client client }): 
        _uri = _buildFullUri(apiKey),
        _client = client ?? new Client();

    static String _buildFullUri(String key) =>
        'https://dictionary.yandex.net/api/v1/dicservice.json/lookup?key=$key&lang=en-ru';

    Future<Article> lookUp(String word) async {
        final response = await _client.post(_uri + '&text=$word');
        return new Article.fromJson(jsonDecode(response.body));
    }

    dispose() {
        _client?.close();
    }
}
