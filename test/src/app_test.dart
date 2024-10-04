import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/app.dart';
import '../mocks/pack_storage_mock.dart';
import '../mocks/root_widget_mock.dart';
import '../testers/language_pair_selector_tester.dart';
import '../testers/preferences_tester.dart';
import '../testers/selector_dialog_tester.dart';
import '../utilities/localizator.dart';
import '../utilities/widget_assistant.dart';

void main() {
  testWidgets(
      "Replaces the language pair selector's icon with a non-empty indicator of a choosen pair",
      (WidgetTester tester) async {
    PreferencesTester.resetSharedPreferences();

    final packStorage = PackStorageMock(singleLanguagePair: false);
    final langPairsToShow = await packStorage.fetchLanguagePairs();

    await tester.pumpWidget(
        RootWidgetMock.buildAsAppHome(child: App(packStorage: packStorage)));
    final assistant = new WidgetAssistant(tester);
    await assistant.pumpAndAnimate();

    await assistant
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
}
