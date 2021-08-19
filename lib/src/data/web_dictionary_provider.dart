import 'dart:convert' show jsonDecode;
import 'package:http/http.dart';
import 'dictionary_provider.dart';
import '../models/article.dart';

class WebDictionaryProvider extends DictionaryProvider {
    final String _key;
	
    final Client _client;

	static List<String> _acceptedLangs;

    WebDictionaryProvider(String apiKey, { Client client }): 
		_key = apiKey,
        _client = client ?? new Client();

	Uri _buildRootUri(String method, [Map<String, String> queryParams]) {
		final params = { 'key': _key };
		if (queryParams != null)
			params.addAll(queryParams);

		return new Uri(
			host: 'dictionary.yandex.net', 
			pathSegments: ['api', 'v1', 'dicservice.json', method],
			queryParameters: params
		);
	}

  	@override
    Future<Article> lookUp(String langParam, String word) {
		return _sendLookUpRequest(_buildSearchUri(langParam), word);
    }

	@override
	Future<List<String>> getAcceptedLanguages() async {
		if (_acceptedLangs == null) {
			final langListUri = _buildRootUri('getLangs');

			final response = await _client.get(
				Uri.https(langListUri.authority, langListUri.path, langListUri.queryParameters));
			_acceptedLangs = (jsonDecode(response.body) as List).cast<String>();
		}

		return _acceptedLangs;
	}

	Uri _buildSearchUri(String langPair) => _buildRootUri('lookup', { 'lang': langPair });

	Future<Article> _sendLookUpRequest(Uri rootUri, String text) async {
		final params = new Map<String, dynamic>.of(rootUri.queryParameters);
		params['text'] = text;

		final response = await _client.post(Uri.https(rootUri.authority, rootUri.path, params));
		return new Article.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
	}

	@override
    void dispose() => _client?.close();
	
  	@override
  	Future<Iterable<String>> searchForLemmas(String langParam, String text) => Future.value([]);
}
