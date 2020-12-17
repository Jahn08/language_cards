class DictionaryParams {
    static const String _api_key_prop_name = 'api_key';

    final String apiKey;

    DictionaryParams({ this.apiKey });

    DictionaryParams.fromJson(Map<String, dynamic> json): 
        apiKey = json[_api_key_prop_name];

    DictionaryParams merge(DictionaryParams params) {
        if (params?.apiKey == null || params.apiKey.isEmpty)
            return new DictionaryParams(apiKey: apiKey);

        return new DictionaryParams(apiKey: params.apiKey);
    }

    Map<String, dynamic> toJson() => { _api_key_prop_name: apiKey };
}

class AppParams {
    static const String _dictionary_prop_name = 'dictionary';

    final DictionaryParams dictionary;

    AppParams({ this.dictionary });

    AppParams.fromJson(Map<String, dynamic> json): 
        dictionary = new DictionaryParams.fromJson(json[_dictionary_prop_name]);

    AppParams merge(AppParams params) {
        return new AppParams(dictionary: params?.dictionary ?? dictionary);
    }

    Map<String, dynamic> toJson() => {_dictionary_prop_name: dictionary };
}
