import 'package:language_cards/src/data/dictionary_provider.dart';
import 'package:language_cards/src/models/word.dart';
import 'package:language_cards/src/models/article.dart';
import '../testers/word_dictionary_tester.dart';

class DictionaryProviderMock implements DictionaryProvider {

	static List<String> _acceptedLanguages;

	final BaseArticle<Word> Function(String text) onLookUp;

	final Iterable<String> Function(String text) onSearchForLemmas;

	DictionaryProviderMock({ this.onLookUp, this.onSearchForLemmas });

	@override
	Future<List<String>> getAcceptedLanguages() {
		return Future.value(_acceptedLanguages ?? 
			(_acceptedLanguages = WordDictionaryTester.buildAcceptedLanguagesResponse()));
	}

	@override
	Future<bool> isTranslationPossible(String langParam) async {
		return (await getAcceptedLanguages()).contains(langParam);
	}

	@override
	Future<BaseArticle<Word>> lookUp(String langParam, String text) async {
		if (!await isTranslationPossible(langParam))
			return null;
		
		return onLookUp?.call(text);
	}

	@override
	Future<Iterable<String>> searchForLemmas(String langParam, String text) async {
		if (!await isTranslationPossible(langParam))
			return null;

		return onSearchForLemmas?.call(text);
	}

	@override
	void dispose() {}
}
