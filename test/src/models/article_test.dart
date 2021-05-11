import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/article.dart';
import '../../testers/word_dictionary_tester.dart';

main() {

	test('Merges articles excluding equal words', () {
		final firstArticle = Article.fromJson(WordDictionaryTester.buildArticleJson());
		final firstDefinition = firstArticle.words.first;

		final secondArticle = Article.fromJson(
			WordDictionaryTester.buildArticleJson(text: firstDefinition.text,
				partOfSpeech: firstDefinition.partOfSpeech)
		);

		final mergedArticle = firstArticle.mergeWords(secondArticle);
		expect(firstArticle.words.length + 
			secondArticle.words.where((w) => !firstArticle.words.contains(w)).length, 
			mergedArticle.words.length);
		expect(firstArticle.words.every((w) => mergedArticle.words.contains(w)), true);
		expect(secondArticle.words.every((w) => mergedArticle.words.contains(w)), true);
	});

	test('Merges article texts for either each found part of speech or the first one', () {
		final firstArticle = Article.fromJson(WordDictionaryTester.buildArticleJson());
		final secondArticle = Article.fromJson(WordDictionaryTester.buildArticleJson(
			partOfSpeech: firstArticle.words.last.partOfSpeech
		));

		final mergedArticle = secondArticle.mergeWordTexts(firstArticle);
		mergedArticle.words.forEach((w) { 
			final firstArticleFirstDefinition = firstArticle.words.firstWhere(
				(sw) => sw.partOfSpeech == w.partOfSpeech, 
				orElse: () => firstArticle.words.first
			);
			expect(w.text, firstArticleFirstDefinition.text);
			expect(w.transcription, firstArticleFirstDefinition.transcription);
			expect(w.translations.every(
				(mt) => !firstArticleFirstDefinition.translations.contains(mt)), true);
		});
	});
}
