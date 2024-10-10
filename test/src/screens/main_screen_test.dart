import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/blocs/settings_bloc.dart';
import 'package:language_cards/src/models/user_params.dart';
import 'package:language_cards/src/screens/main_screen.dart';
import 'package:language_cards/src/widgets/translation_indicator.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/root_widget_mock.dart';
import '../../testers/dialog_tester.dart';
import '../../testers/language_pair_selector_tester.dart';
import '../../testers/preferences_tester.dart';
import '../../testers/selector_dialog_tester.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/widget_assistant.dart';

void main() {
  testWidgets(
      "Shows the language pair selector and available pairs in its dialog",
      (WidgetTester tester) async {
    await PreferencesTester.saveDefaultUserParams();

    final packStorage = PackStorageMock(singleLanguagePair: false);
    final langPairsToShow = await packStorage.fetchLanguagePairs();

    final chosenLangPair = Randomiser.nextElement(langPairsToShow);
    final params = new UserParams();
    params.languagePair = chosenLangPair;
    await PreferencesTester.saveParams(params);

    await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
        child: new SettingsBlocProvider(
            child: MainScreen(packStorage: packStorage))));
    final assistant = new WidgetAssistant(tester);
    await assistant.pumpAndAnimate();

    final pairSelectorFinder =
        LanguagePairSelectorTester.assureNonEmptyPairSelector(
            tester, chosenLangPair);
    await assistant.tapWidget(pairSelectorFinder);
    DialogTester.assureDialog(shouldFind: true);

    final locale = Localizator.defaultLocalization;
    SelectorDialogTester.assureRenderedOptions(
        tester,
        LanguagePairSelectorTester.prepareLanguagePairsForDisplay(
            langPairsToShow, locale), (finder, pair) {
      final option = tester.widget<SimpleDialogOption>(finder);

      final optionTile = option.child! as ListTile;
      final pairIndicator = optionTile.title! as TranslationIndicator;

      if (pair.isEmpty) {
        expect(pairIndicator.from, null);
        expect(pairIndicator.to, null);

        expect((optionTile.subtitle! as Text).data,
            locale.languagePairSelectorNoneLanguagePairName);
      } else {
        expect(pairIndicator.from, pair.from);
        expect(pairIndicator.to, pair.to);

        expect((optionTile.subtitle! as Text).data, pair.present(locale));
      }

      expect(optionTile.trailing != null, pair == chosenLangPair);
    }, ListTile);
  });
}
