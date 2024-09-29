import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/blocs/settings_bloc.dart';
import 'package:language_cards/src/data/preferences_provider.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/user_params.dart';
import 'package:language_cards/src/widgets/language_pair_selector.dart';
import 'package:language_cards/src/widgets/translation_indicator.dart';
import '../../mocks/root_widget_mock.dart';
import '../../testers/cancellable_dialog_tester.dart';
import '../../testers/dialog_tester.dart';
import '../../testers/language_pair_selector_tester.dart';
import '../../testers/preferences_tester.dart';
import '../../testers/selector_dialog_tester.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/widget_assistant.dart';

enum _ChosenLangPairVariant {
  empty,

  nonEmpty
}

void main() {
  testWidgets(
      'Shows no language pair selector when there is no pair chosen and there are not enough pairs',
      (WidgetTester tester) async {
    PreferencesTester.resetSharedPreferences();

    await _pumpLanguagePairSelectorWidget(tester, {});
    AssuredFinder.findOne(type: IconButton, shouldFind: false);

    await _pumpLanguagePairSelectorWidget(
        tester, {const LanguagePair(Language.french, Language.italian)});
    AssuredFinder.findOne(type: IconButton, shouldFind: false);
  });

  testWidgets(
      'Shows the language pair selector with an empty flag icon when there is no pair chosen from available pairs',
      (WidgetTester tester) async {
    PreferencesTester.resetSharedPreferences();

    final langPairsToShow = {
      const LanguagePair(Language.english, Language.german),
      const LanguagePair(Language.english, Language.spanish)
    };
    await _pumpLanguagePairSelectorWidget(tester, langPairsToShow);

    final assistant = new WidgetAssistant(tester);
    await assistant
        .tapWidget(LanguagePairSelectorTester.findEmptyPairSelector());
    DialogTester.assureDialog(shouldFind: true);

    SelectorDialogTester.assureRenderedOptions(
        tester, langPairsToShow.toList()..insert(0, LanguagePair.empty()),
        (finder, pair) {
      final option = tester.widget<SimpleDialogOption>(finder);

      final optionTile = option.child! as ListTile;
      final pairIndicator = optionTile.title! as TranslationIndicator;

      if (pair.isEmpty) {
        expect(pairIndicator.from, null);
        expect(pairIndicator.to, null);

        expect(
            (optionTile.subtitle! as Text).data,
            Localizator
                .defaultLocalization.languagePairSelectorNoneLanguagePairName);
        expect(optionTile.trailing != null, true);
      } else {
        expect(pairIndicator.from, pair.from);
        expect(pairIndicator.to, pair.to);

        expect((optionTile.subtitle! as Text).data,
            pair.present(Localizator.defaultLocalization));
        expect(optionTile.trailing, null);
      }
    }, ListTile);
  });

  final chosenPackVar = ValueVariant<_ChosenLangPairVariant>(
      _ChosenLangPairVariant.values.toSet());

  testWidgets(
      'Shows the language pair selector with an indicator of a pair when there is a pair chosen',
      (WidgetTester tester) async {
    final isEmptyPairChosen =
        chosenPackVar.currentValue == _ChosenLangPairVariant.empty;
    final chosenLangPair = isEmptyPairChosen
        ? LanguagePair.empty()
        : const LanguagePair(Language.english, Language.spanish);
    final params = new UserParams();
    params.languagePair = chosenLangPair;

    await PreferencesTester.saveParams(params);

    final langPairsToShow = {
      const LanguagePair(Language.english, Language.spanish),
      const LanguagePair(Language.spanish, Language.english)
    };
    await _pumpLanguagePairSelectorWidget(tester, langPairsToShow);

    final pairSelectorFinder = isEmptyPairChosen
        ? LanguagePairSelectorTester.findEmptyPairSelector()
        : LanguagePairSelectorTester.assureNonEmptyPairSelector(
            tester, chosenLangPair);
    await new WidgetAssistant(tester).tapWidget(pairSelectorFinder);

    SelectorDialogTester.assureRenderedOptions(
        tester, langPairsToShow.toList()..insert(0, LanguagePair.empty()),
        (finder, pair) {
      final option = tester.widget<SimpleDialogOption>(finder);

      final optionTile = option.child! as ListTile;
      expect(optionTile.trailing != null, pair == chosenLangPair);
    }, ListTile);
  }, variant: chosenPackVar);

  testWidgets(
      'Shows the language pair selector with an indicator of a pair when there is a non-existent pair chosen',
      (WidgetTester tester) async {
    const chosenLangPair = LanguagePair(Language.english, Language.french);

    final params = new UserParams();
    params.languagePair = chosenLangPair;

    await PreferencesTester.saveParams(params);

    final langPairsToShow = {
      const LanguagePair(Language.english, Language.spanish),
      const LanguagePair(Language.spanish, Language.english)
    };
    await _pumpLanguagePairSelectorWidget(tester, langPairsToShow);

    final pairIndicatorFinder =
        LanguagePairSelectorTester.assureNonEmptyPairSelector(tester, chosenLangPair);
    await new WidgetAssistant(tester).tapWidget(pairIndicatorFinder);

    SelectorDialogTester.assureRenderedOptions(
        tester,
        langPairsToShow.toList()
          ..insert(0, chosenLangPair)
          ..insert(0, LanguagePair.empty()), (finder, pair) {
      final option = tester.widget<SimpleDialogOption>(finder);

      final optionTile = option.child! as ListTile;
      expect(optionTile.trailing != null, pair == chosenLangPair);
    }, ListTile);
  });

  testWidgets('Chooses the language pair and saves it into the app preferences',
      (WidgetTester tester) async {
    PreferencesTester.resetSharedPreferences();

    final langPairsToShow = {
      const LanguagePair(Language.english, Language.italian),
      const LanguagePair(Language.french, Language.russian)
    };
    await _pumpLanguagePairSelectorWidget(tester, langPairsToShow);

    await new WidgetAssistant(tester)
        .tapWidget(LanguagePairSelectorTester.findEmptyPairSelector());

    await SelectorDialogTester.assureTappingItem(
        tester, langPairsToShow.toList()..insert(0, LanguagePair.empty()), 2);

    final savedUserParams = await PreferencesProvider.fetch();
    expect(const LanguagePair(Language.french, Language.russian),
        savedUserParams.languagePair);
  });

  testWidgets(
      'Saves no language pair into the app preferences when the selector dialog is cancelled',
      (WidgetTester tester) async {
    const chosenPair = LanguagePair(Language.english, Language.spanish);
    final params = new UserParams();
    params.languagePair = chosenPair;

    await PreferencesTester.saveParams(params);

    final settingsBloc = await _pumpLanguagePairSelectorWidget(tester, {
      const LanguagePair(Language.english, Language.italian),
      const LanguagePair(Language.french, Language.russian)
    });

    bool settingsSaved = false;
    settingsBloc.addOnSaveListener((_) => settingsSaved = true);

    await new WidgetAssistant(tester)
        .tapWidget(LanguagePairSelectorTester.findNonEmptyPairSelector());

    await CancellableDialogTester.cancelDialog(tester);

    final savedUserParams = await PreferencesProvider.fetch();
    expect(chosenPair, savedUserParams.languagePair);
    expect(settingsSaved, false);
  });

  testWidgets(
      'Saves no language pair into the app preferences when the same pair is chosen',
      (WidgetTester tester) async {
    const chosenPair = LanguagePair(Language.spanish, Language.english);
    final params = new UserParams();
    params.languagePair = chosenPair;

    await PreferencesTester.saveParams(params);

    final langPairsToShow = {
      const LanguagePair(Language.english, Language.italian),
      const LanguagePair(Language.french, Language.russian)
    };
    final settingsBloc =
        await _pumpLanguagePairSelectorWidget(tester, langPairsToShow);

    bool settingsSaved = false;
    settingsBloc.addOnSaveListener((_) => settingsSaved = true);

    await new WidgetAssistant(tester)
        .tapWidget(LanguagePairSelectorTester.findNonEmptyPairSelector());

    await SelectorDialogTester.assureTappingItem(
        tester,
        langPairsToShow.toList()
          ..add(chosenPair)
          ..insert(0, LanguagePair.empty()),
        3);

    final savedUserParams = await PreferencesProvider.fetch();
    expect(chosenPair, savedUserParams.languagePair);
    expect(settingsSaved, false);
  });
}

Future<SettingsBloc> _pumpLanguagePairSelectorWidget(
    WidgetTester tester, Set<LanguagePair> langPairs) async {
  await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
      child: new SettingsBlocProvider(child: LanguagePairSelector(langPairs))));
  await new WidgetAssistant(tester).pumpAndAnimate();

  final BuildContext selectorContext =
      tester.element(find.byType(LanguagePairSelector));
  return SettingsBlocProvider.of(selectorContext)!;
}
