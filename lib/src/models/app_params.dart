import '../utilities/string_ext.dart';

class DictionaryParams {
    static const String _apiKeyPropName = 'api_key';

    final String apiKey;

    DictionaryParams({ this.apiKey });

    DictionaryParams.fromJson(Map<String, dynamic> json): 
        apiKey = json[_apiKeyPropName];

    DictionaryParams merge(DictionaryParams params) => 
		new DictionaryParams(apiKey: getValueOrDefault(params?.apiKey, apiKey));

    Map<String, dynamic> toJson() => { _apiKeyPropName: apiKey };
}

class ContactsParams {
    static const String _fbLinkPropName = 'facebook';
    static const String _emailPropName = 'email';
	static const String _appStoreIdPropName = 'app_store_id';

    final String fbLink;

    final String email;

    final String appStoreId;

    ContactsParams({ this.fbLink, this.email, this.appStoreId });

    ContactsParams.fromJson(Map<String, dynamic> json): 
        fbLink = json[_fbLinkPropName],
        appStoreId = json[_appStoreIdPropName],
        email = json[_emailPropName];

    ContactsParams merge(ContactsParams params) =>
		new ContactsParams(
			fbLink: getValueOrDefault(params?.fbLink, fbLink),
			email: getValueOrDefault(params?.email, email),
			appStoreId: getValueOrDefault(params?.appStoreId, appStoreId)
		);

    Map<String, dynamic> toJson() => { _fbLinkPropName: fbLink };
}

class AppParams {
    static const String _dictionaryPropName = 'dictionary';
    static const String _contactsPropName = 'contacts';

    final DictionaryParams dictionary;

    final ContactsParams contacts;

    AppParams({ this.dictionary, this.contacts});

    AppParams.fromJson(Map<String, dynamic> json): 
        dictionary = new DictionaryParams.fromJson(json[_dictionaryPropName]),
		contacts = new ContactsParams.fromJson(json[_contactsPropName]);

    AppParams merge(AppParams params) {
        return new AppParams(dictionary: params?.dictionary ?? dictionary,
			contacts: params?.contacts ?? contacts);
    }

    Map<String, dynamic> toJson() => {_dictionaryPropName: dictionary };
}
