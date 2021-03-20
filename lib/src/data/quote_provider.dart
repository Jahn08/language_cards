import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:math';

class QuoteProvider {

	static final _quoteCache = <String, List<String>>{};

	QuoteProvider._();

	static MapEntry<String, String> getNextQuote(AppLocalizations locale) {
		final quoteDic = _getQuotes(locale);
		final entry = quoteDic.elementAt(new Random().nextInt(quoteDic.length));
		
	 	return _separateTextFromSource(entry);
	}

	static List<String> _getQuotes(AppLocalizations locale) {
		final localeName = locale.localeName;
		if (!_quoteCache.containsKey(localeName)) {
			_quoteCache[localeName] = <String>[
				locale.quote1, locale.quote2, locale.quote3, locale.quote4, locale.quote5,
				locale.quote6, locale.quote7, locale.quote8, locale.quote9, locale.quote10,
				locale.quote11, locale.quote12, locale.quote13, locale.quote14, locale.quote15,
				locale.quote16, locale.quote17, locale.quote18, locale.quote19, locale.quote20,
				locale.quote21, locale.quote22, locale.quote23, locale.quote24, locale.quote25,
				locale.quote26, locale.quote27
			];
		}

		return _quoteCache[localeName];
	}

	static MapEntry<String, String> _separateTextFromSource(String quote) {
		final parts = quote.split('@');
		return new MapEntry(parts.first, parts.last);
	}
}
