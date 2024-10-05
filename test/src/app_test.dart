import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/app.dart';
import 'package:language_cards/src/consts.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/user_params.dart';
import '../mocks/pack_storage_mock.dart';
import '../mocks/root_widget_mock.dart';
import '../testers/language_pair_selector_tester.dart';
import '../testers/preferences_tester.dart';
import '../testers/selector_dialog_tester.dart';
import '../utilities/assured_finder.dart';
import '../utilities/localizator.dart';
import '../utilities/randomiser.dart';
import '../utilities/storage_fetcher.dart';
import '../utilities/widget_assistant.dart';

void main() {
  testWidgets(
      "Replaces the language pair selector's icon with a non-empty indicator of a choosen pair",
      (WidgetTester tester) async {
    PreferencesTester.resetSharedPreferences();

    final packStorage = PackStorageMock(singleLanguagePair: false);
    final langPairsToShow = await packStorage.fetchLanguagePairs();

    await _pumpAppWidget(tester, packStorage);
    await new WidgetAssistant(tester)
        .tapWidget(LanguagePairSelectorTester.findEmptyPairSelector());

    final sortedPairs =
        LanguagePairSelectorTester.prepareLanguagePairsForDisplay(
            langPairsToShow, Localizator.defaultLocalization);
    const chosenPairIndex = 1;
    await SelectorDialogTester.assureTappingItem(
        tester, sortedPairs, chosenPairIndex);

    final expectedChosenPair = sortedPairs[chosenPairIndex];
    LanguagePairSelectorTester.assureNonEmptyPairSelector(
        tester, expectedChosenPair);
  });

  testWidgets("Renders the pack screen with packs filtered by a language pair",
      (WidgetTester tester) async {
    final packStorage = PackStorageMock(singleLanguagePair: false);
    final chosenLangPair = await _saveLanguagePairToSettings(packStorage);

    await _pumpAppWidget(tester, packStorage);
    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(AssuredFinder.findOne(
        type: ElevatedButton, icon: Consts.packListIcon, shouldFind: true));

    final langPairPacks = await packStorage.fetch(languagePair: chosenLangPair);
    final itemsLength = langPairPacks.length;

    final listItemFinders = find.byType(ListTile);
    expect(listItemFinders, findsNWidgets(itemsLength));

    for (int i = 0; i < itemsLength; ++i) {
      final pack = langPairPacks[i];
      expect(
          find.descendant(
              of: listItemFinders.at(i), matching: find.text(pack.name)),
          findsOneWidget);
    }
  });

  testWidgets(
      "Renders the study preparer screen with packs filtered by a language pair",
      (WidgetTester tester) async {
    final packStorage = PackStorageMock(singleLanguagePair: false);
    final chosenLangPair = await _saveLanguagePairToSettings(packStorage);

    await _pumpAppWidget(tester, packStorage);
    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(AssuredFinder.findOne(
        type: ElevatedButton,
        icon: Consts.studyPreparationIcon,
        shouldFind: true));

    final packsByLangPair = await StorageFetcher.fetchNamedPacks(packStorage,
        langPair: chosenLangPair);
    final itemsLength = packsByLangPair.length;

    final itemFinders = find.byType(CheckboxListTile);
    expect(itemFinders, findsNWidgets(itemsLength));

    for (int i = 0; i < itemsLength; ++i) {
      final pack = packsByLangPair[i];
      expect(
          find.descendant(
              of: itemFinders.at(i), matching: find.text(pack.name)),
          findsOneWidget);
    }
  });

  testWidgets("Renders the card screen with cards filtered by a language pair",
      (WidgetTester tester) async {
    final packStorage = PackStorageMock(singleLanguagePair: false);
    final chosenLangPair = await _saveLanguagePairToSettings(packStorage);

    await _pumpAppWidget(tester, packStorage);
    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(AssuredFinder.findOne(
        type: ElevatedButton, icon: Consts.cardListIcon, shouldFind: true));

    final packsByLangPair =
        await packStorage.fetch(languagePair: chosenLangPair);
    final wordsByLangPair = await StorageFetcher.fetchPackedCards(
        packsByLangPair, packStorage.wordStorage);
    final itemsLength = wordsByLangPair.length;

    final listItemFinders = find.descendant(
        of: find.byType(Dismissible, skipOffstage: false),
        matching: find.byType(ListTile, skipOffstage: false),
        skipOffstage: false);
    expect(listItemFinders, findsNWidgets(itemsLength));

    for (int i = 0; i < itemsLength; ++i) {
      final word = wordsByLangPair[i];
      expect(
          find.descendant(
              of: listItemFinders.at(i),
              matching: find.text(word.text, skipOffstage: false)),
          findsOneWidget);
    }
  });
}

Future _pumpAppWidget(WidgetTester tester, PackStorageMock packStorage) async {
  await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
      child:
          App(packStorage: packStorage, wordStorage: packStorage.wordStorage)));
  await new WidgetAssistant(tester).pumpAndAnimate();
}

Future<LanguagePair> _saveLanguagePairToSettings(
    PackStorageMock storage) async {
  PreferencesTester.resetSharedPreferences();

  final langPairs = await storage.fetchLanguagePairs();
  final chosenLangPair = Randomiser.nextElement(langPairs);

  final params = new UserParams();
  params.languagePair = chosenLangPair;
  await PreferencesTester.saveParams(params);

  return chosenLangPair;
}
