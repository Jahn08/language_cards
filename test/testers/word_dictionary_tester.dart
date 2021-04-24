import 'package:http/http.dart';
import 'package:language_cards/src/data/dictionary_provider.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/part_of_speech.dart';
import '../utilities/randomiser.dart';

class WordDictionaryTester {

	WordDictionaryTester._();
	
	static Object buildEmptyArticleJson() => _buildArticle([]);
	
	static Object buildArticleJson({ String text, PartOfSpeech partOfSpeech }) {
		text = text ?? Randomiser.nextString();
		partOfSpeech = partOfSpeech ?? Randomiser.nextElement(PartOfSpeech.values);

		final usedPos = <PartOfSpeech>[partOfSpeech];
		return _buildArticle(List.generate(Randomiser.nextInt(3) + 2, (index) {
			if (index > 0) {
				do {
					partOfSpeech = Randomiser.nextElement(PartOfSpeech.values);
				} while (usedPos.contains(partOfSpeech));
				usedPos.add(partOfSpeech);
			}

			return _buildWordDefinition(text ?? Randomiser.nextString(), partOfSpeech.value);
		}));
	}

	static Object _buildArticle(List<Object> wordsDefinitions) => ({ "def": wordsDefinitions });

	static Object _buildWordDefinition(String text, String partOfSpeech) {
		return {"text": text, "pos": partOfSpeech, "ts": Randomiser.nextString(), 
			"tr": List.generate(Randomiser.nextInt(3) + 1, (_) => _buildTranslation())
		};
	}

	static Object _buildTranslation() => {"text": Randomiser.nextString()};

	static List<String> buildAcceptedLanguagesResponse([Language from = Language.english]) {
		return new Set.from(Language.values.map((to) => [buildLangPair(from, to), 
			buildLangPair(to, from)]).expand((v) => v)).cast<String>().toList();
	}

	static buildLangPair(Language from, Language to) => 
		DictionaryProvider.buildLangPair(DictionaryProvider.representLanguage(from), 
			DictionaryProvider.representLanguage(to));

	static bool isLookUpRequest(Request req) => req.url.queryParameters.length > 1;
}
