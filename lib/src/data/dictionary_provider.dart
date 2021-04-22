import '../models/article.dart';
import '../models/language.dart';

abstract class DictionaryProvider {

	Future<bool> isTranslationPossible(String langParam);
	
	Future<Article> lookUp(String langParam, String text);

	void dispose();
	
	static String buildLangPair(String from, String to) => '$from-$to';

	static String representLanguage(Language lang) {
		switch (lang) {
        	case Language.english:
				return 'en';
			case Language.spanish:
				return 'es';
			case Language.russian:
				return 'ru';
			case Language.german:
				return 'de';
			case Language.french:
				return 'fr';
        	case Language.italian:
				return 'it';
			default:
				return '';
		}
	}
}
