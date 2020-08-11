class DictionaryParams {
    static const String _API_KEY_PROP_NAME = 'api_key';

    final String apiKey;

    DictionaryParams({ this.apiKey });

    DictionaryParams.fromJson(Map<String, dynamic> json): 
        apiKey = json[_API_KEY_PROP_NAME];

    DictionaryParams merge(DictionaryParams params) {
        if (params?.apiKey == null || params.apiKey.isEmpty)
            return new DictionaryParams(apiKey: apiKey);

        return new DictionaryParams(apiKey: params.apiKey);
    }

    Map<String, dynamic> toJson() => { _API_KEY_PROP_NAME: apiKey };
}

class AppParams {
    static const String _DICTIONARY_PROP_NAME = 'dictionary';

    final DictionaryParams dictionary;

    AppParams({ this.dictionary });

    AppParams.fromJson(Map<String, dynamic> json): 
        dictionary = new DictionaryParams.fromJson(json[_DICTIONARY_PROP_NAME]);

    AppParams merge(AppParams params) {
        return new AppParams(dictionary: params?.dictionary ?? dictionary);
    }

    Map<String, dynamic> toJson() => {_DICTIONARY_PROP_NAME: dictionary };
}
