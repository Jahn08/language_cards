import 'package:meta/meta.dart';
import '../models/article.dart';
import '../models/language.dart';
import './dictionary_provider.dart';

class WordDictionary {

	static const int searcheableLemmaMaxNumber = 5;

	final String _from;
	
	final String _to;

    final DictionaryProvider provider;
	
    WordDictionary(this.provider, { @required Language from, Language to }): 
		_from = DictionaryProvider.representLanguage(from),
		_to = DictionaryProvider.representLanguage(to ?? from);

	Future<List<String>> searchForLemmas(String text) async {
		if (provider == null)
			return [];

		final directLangPair = DictionaryProvider.buildLangPair(_from, _to);
		
		if (await provider.isTranslationPossible(directLangPair))
			return (await provider.searchForLemmas(directLangPair, text))
				.take(searcheableLemmaMaxNumber).toList();
		
		return [];
    }

    Future<BaseArticle> lookUp(String word) async {
		if (provider == null)
			return null;

		final directLangPair = DictionaryProvider.buildLangPair(_from, _to);
		
		if (!await provider.isTranslationPossible(directLangPair))
			return null;	
			
		return provider.lookUp(directLangPair, word);
    }

	Future<bool> isTranslationPossible() =>
		provider == null ? Future.value(false): 
			provider.isTranslationPossible(DictionaryProvider.buildLangPair(_from, _to));

	void dispose() => provider?.dispose();
}
