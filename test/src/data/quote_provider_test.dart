import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/quote_provider.dart';
import '../../utilities/localizator.dart';

main() {

	test('Retrieves quotes from the dictionary for distinct locales', () {
		final defLocale = Localizator.defaultLocalization;
		final firstQuote = QuoteProvider.getNextQuote(defLocale);
		final secondQuote = QuoteProvider.getNextQuote(defLocale);
		expect(firstQuote.key != secondQuote.key, true);

		final rusLocale = Localizator.russianLocalization;
		final firstRusQuote = QuoteProvider.getNextQuote(rusLocale);
		_assureTextIsInRussian(firstRusQuote.key);
		_assureTextIsInRussian(firstRusQuote.value);

		final secondRusQuote = QuoteProvider.getNextQuote(rusLocale);
		_assureTextIsInRussian(secondRusQuote.key);
		_assureTextIsInRussian(secondRusQuote.value);

		expect(firstRusQuote.key != secondRusQuote.key, true);
		
		final rusQuoteTexts = [firstRusQuote.key, secondRusQuote.key];
		expect([firstQuote.key, secondQuote.key]
			.every((q) => !rusQuoteTexts.contains(q)), true);
	
		final rusQuoteSources = [firstRusQuote.value, secondRusQuote.value];
		expect([firstQuote.value, secondQuote.value]
			.every((q) => !rusQuoteSources.contains(q)), true);
	});
}

void _assureTextIsInRussian(String quote) => 
	expect(quote.replaceAll(
		new RegExp(r'([А-Я]|\W)+', multiLine: true, caseSensitive: false), '').isEmpty, true);
