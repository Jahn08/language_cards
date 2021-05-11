import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:language_cards/src/data/web_dictionary_provider.dart';
import 'package:language_cards/src/data/word_dictionary.dart';
import 'package:language_cards/src/models/article.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/word.dart';
import '../../testers/word_dictionary_tester.dart';
import '../../utilities/http_responder.dart';
import '../../utilities/randomiser.dart';

void main() {

    test('Returns a word article describing word translations and properties', () async {
		final articleJson = WordDictionaryTester.buildArticleJson();
		final expectedArticle = new Article.fromJson(articleJson);
		
		final client = new MockClient((request) async =>
			HttpResponder.respondWithJson(WordDictionaryTester.isLookUpRequest(request) ? 
				articleJson: WordDictionaryTester.buildAcceptedLanguagesResponse()));

        final article = await new WordDictionary(
			new WebDictionaryProvider(Randomiser.nextString(), client: client),
			from: Language.english
		).lookUp(expectedArticle.words.first.text);
		_assureWords(expectedArticle, article.words);
    });

    test('Returns an empty word article for an unknown word', () async {
        final client = new MockClient((request) async => 
			HttpResponder.respondWithJson(WordDictionaryTester.isLookUpRequest(request) ? 
				WordDictionaryTester.buildEmptyArticleJson(): 
				WordDictionaryTester.buildAcceptedLanguagesResponse()));

        final unknownWord = Randomiser.nextString();
        final article = await new WordDictionary(
			new WebDictionaryProvider(Randomiser.nextString(), client: client),
			from: Language.english
		).lookUp(unknownWord);
        expect(article?.words?.length, 0);
    });

    test('Sends request to a properly built URL with containing an api key and searched word', 
        () async {
            Uri url;
            final client = new MockClient((request) async {
                url = request.url;
				return HttpResponder.respondWithJson(WordDictionaryTester.isLookUpRequest(request) ? 
					WordDictionaryTester.buildEmptyArticleJson(): 
					WordDictionaryTester.buildAcceptedLanguagesResponse());
            });

            final expectedWord = Randomiser.nextString();
            final expectedApiKey = Randomiser.nextString();
            await new WordDictionary(
				new WebDictionaryProvider(expectedApiKey, client: client),
                from: Language.english
			).lookUp(expectedWord);
            
            expect(url == null, false);
            expect(url.query?.isEmpty, false);

            expect(url.queryParameters['key'], expectedApiKey);
            expect(url.queryParameters['text'], expectedWord);
        });

	test('Returns a word article with an indirect translation', () async {
		final fromItArticleJson = WordDictionaryTester.buildArticleJson();
		final expectedFromItArticle = new Article.fromJson(fromItArticleJson);

		final toFrArticleJson = WordDictionaryTester.buildArticleJson();
		final expectedFrArticle = new Article.fromJson(toFrArticleJson);
		
		final wordToLookUp = expectedFromItArticle.words.first.text;
		
		final params = <Map<String, String>>[];
		final client = new MockClient((request) async {
			if (!WordDictionaryTester.isLookUpRequest(request))
				return HttpResponder.respondWithJson(WordDictionaryTester.buildAcceptedLanguagesResponse());

			params.add(request.url.queryParameters);
			return HttpResponder.respondWithJson(
				params.length == 1 ? fromItArticleJson: toFrArticleJson);
		});
			
        final article = await new WordDictionary(
			new WebDictionaryProvider(Randomiser.nextString(), client: client),
			from: Language.italian, 
			to: Language.french
		).lookUp(wordToLookUp);

		expect(params.length, expectedFromItArticle.words.expand((w) => w.translations).length + 1);
		expect(params.first.containsValue(
			WordDictionaryTester.buildLangPair(Language.italian, Language.english)), true);
		expect(params.skip(1).every((p) => p.containsValue(
			WordDictionaryTester.buildLangPair(Language.english, Language.french))), true);

		_assureWords(expectedFrArticle.mergeWordTexts(expectedFromItArticle), article.words);
	});

	test('Returns an empty word article for an indirect translation', () async {
		final params = <Map<String, String>>[];
		final client = new MockClient((request) async {
			if (!WordDictionaryTester.isLookUpRequest(request))
				return HttpResponder.respondWithJson(WordDictionaryTester.buildAcceptedLanguagesResponse());

			params.add(request.url.queryParameters);
			return HttpResponder.respondWithJson({});
		});
			
        final article = await new WordDictionary(
			new WebDictionaryProvider(Randomiser.nextString(), client: client),
			from: Language.italian, 
			to: Language.french
		).lookUp(Randomiser.nextString());
		expect(article.words.isEmpty, true);

		expect(params.length, 1);
		expect(params.first.containsValue(
			WordDictionaryTester.buildLangPair(Language.italian, Language.english)), true);
	});
}

void _assureWords(Article expectedArticle, List<Word> actualWords) {
	final expectedWordNumber = expectedArticle.words.length;
	expect(actualWords?.length, expectedWordNumber);
	expect(actualWords.map((word) => word.partOfSpeech).toSet().length, expectedWordNumber);

	final expectedWord = expectedArticle.words.first.text;
	actualWords.forEach((word) { 
		expect(word.text, expectedWord);
		expect(word.translations.isEmpty, false);
	});
}	
