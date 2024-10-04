import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/widgets/translation_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utilities/assured_finder.dart';

class LanguagePairSelectorTester {
  static Finder findEmptyPairSelector({bool shouldFind = true}) =>
      AssuredFinder.findOne(
          type: IconButton, icon: Icons.flag_outlined, shouldFind: shouldFind);

  static Finder findNonEmptyPairSelector({bool shouldFind = true}) =>
      AssuredFinder.findOne(type: TranslationIndicator, shouldFind: shouldFind);

  static Finder assureNonEmptyPairSelector(
      WidgetTester tester, LanguagePair expectedLangPair) {
    final pairSelectorFinder = findNonEmptyPairSelector();
    final indicator = tester.widget<TranslationIndicator>(pairSelectorFinder);
    expect(indicator.from, expectedLangPair.from);
    expect(indicator.to, expectedLangPair.to);

    return pairSelectorFinder;
  }

  static List<LanguagePair> prepareLanguagePairsForDisplay(
      Iterable<LanguagePair> pairs, AppLocalizations locale) {
    return pairs.toList()
      ..sort((a, b) => a.present(locale).compareTo(b.present(locale)))
      ..insert(0, LanguagePair.empty());
  }
}
