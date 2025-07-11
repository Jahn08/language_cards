import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:language_cards/src/blocs/settings_bloc.dart';
import 'package:language_cards/src/data/preferences_provider.dart';
import 'package:language_cards/src/data/study_storage.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/user_params.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/study_preparer_screen.dart';
import 'package:language_cards/src/widgets/card_number_indicator.dart';
import 'package:language_cards/src/widgets/one_line_text.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/root_widget_mock.dart';
import '../../testers/card_editor_tester.dart';
import '../../testers/dialog_tester.dart';
import '../../testers/preferences_tester.dart';
import '../../testers/study_screen_tester.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/storage_fetcher.dart';
import '../../utilities/variants.dart';
import '../../utilities/widget_assistant.dart';

void main() {
  setUp(() => PreferencesTester.saveDefaultUserParams());

  testWidgets(
      'Renders card packs as selected displaying their number of cards and study levels',
      (tester) async {
    final storage = await _pumpScreen(tester);

    final packs = await StorageFetcher.fetchNamedPacks(storage);
    expect(_findCheckTiles(), findsNWidgets(packs.length));

    await _assureConsecutivelyCheckedTiles(tester, packs, (p, packTileFinder) {
      expect(
          find.descendant(
              of: packTileFinder,
              matching: find.text(Localizator.defaultLocalization
                  .cardNumberIndicatorContent(p.cardsNumber.toString()))),
          findsOneWidget);
    });

    final studyPacks = await storage.fetchStudyPacks(null);
    _assureCardNumbersForStudyLevels(studyPacks);

    _findDownwardScrollBtn(shouldFind: false);
  });

  testWidgets('Renders card packs filtered by a language pair', (tester) async {
    final packStorage = new PackStorageMock(singleLanguagePair: false);
    final langPairs = await packStorage.fetchLanguagePairs();
    final chosenLangPair = Randomiser.nextElement(langPairs);

    final storage = await _pumpScreen(tester,
        storage: packStorage, langPair: chosenLangPair);

    final packs =
        await StorageFetcher.fetchNamedPacks(storage, langPair: chosenLangPair);
    expect(_findCheckTiles(), findsNWidgets(packs.length));

    await _assureConsecutivelyCheckedTiles(tester, packs, (p, packTileFinder) {
      expect(find.descendant(of: packTileFinder, matching: find.text(p.name)),
          findsOneWidget);
    });
  });

  testWidgets(
      'Renders the last study date for card packs when it is available and the option is on',
      (tester) async {
    final userParams = await PreferencesProvider.fetch();
    expect(userParams.studyParams.showStudyDate, true);

    await _testRenderingStudyDates(tester, shouldShowDates: true);
  });

  testWidgets(
      'Renders no last study date for card packs when the option is off',
      (tester) async {
    await _hideStudyDate();
    await _testRenderingStudyDates(tester);
  });

  testWidgets(
      'Renders the list of packs by their name in ascending order by default',
      (tester) => _testRenderingPackOrder(tester, PackOrder.byNameAsc));

  testWidgets('Renders the list of packs by their name in descending order',
      (tester) async {
    const exprectedOrder = PackOrder.byNameDesc;
    await _setPackOrderPreference(exprectedOrder);
    await _testRenderingPackOrder(tester, exprectedOrder);
  });

  testWidgets(
      'Renders the list of packs by their study date in ascending order according to the respective setting',
      (tester) async {
    const exprectedOrder = PackOrder.byDateAsc;
    await _setPackOrderPreference(exprectedOrder);
    await _testRenderingPackOrder(tester, exprectedOrder);
  });

  testWidgets(
      'Renders the list of packs by their study date in descending order according to the respective setting',
      (tester) async {
    const exprectedOrder = PackOrder.byDateDesc;
    await _setPackOrderPreference(exprectedOrder);
    await _testRenderingPackOrder(tester, exprectedOrder);
  });

  final returnNavigationWayAndOrder =
      new ValueVariant<DoubleVariant<ReturnNavigationWay, PackOrder>>({
    new DoubleVariant(ReturnNavigationWay.byOSButton, PackOrder.byDateAsc,
        name2: "byDateAsc"),
    new DoubleVariant(ReturnNavigationWay.byBarBackButton, PackOrder.byDateAsc,
        name2: "byDateAsc"),
    new DoubleVariant(ReturnNavigationWay.byOSButton, PackOrder.byDateDesc,
        name2: "byDateDesc"),
    new DoubleVariant(ReturnNavigationWay.byBarBackButton, PackOrder.byDateDesc,
        name2: "byDateDesc")
  });

  testWidgets(
      'Keeps packs ordered by their study date after finishing a study cycle updates the dates',
      (tester) async {
    final packOrder = returnNavigationWayAndOrder.currentValue!.value2;
    await _setPackOrderPreference(packOrder);

    final storage = new PackStorageMock(packsNumber: 7, cardsNumber: 50);
    final assistant = new WidgetAssistant(tester);
    final studyTester = new StudyScreenTester(assistant);

    final packs = await StorageFetcher.fetchNamedPacks(storage);
    final packsToStudy = studyTester.takeEnoughCards(packs);

    await tester.pumpWidget(RootWidgetMock.buildAsAppHomeWithStudyRouting(
        storage: storage, packsToStudy: packsToStudy, noBar: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await assistant.tapWidget(find.widgetWithText(
        ListTile,
        Localizator
            .defaultLocalization.studyPreparerScreenAllCardsCategoryName));

    final cardsToStudy = await StorageFetcher.fetchPackedCards(
        packsToStudy, storage.wordStorage);
    await studyTester.goThroughCardList(cardsToStudy.length,
        byClickingButton: true);

    await assistant.tapWidget(DialogTester.findConfirmationDialogBtn());

    final returnNavigationWay =
        returnNavigationWayAndOrder.currentValue!.value1;
    await (returnNavigationWay == ReturnNavigationWay.byOSButton
        ? assistant.navigateBackByOSButton()
        : assistant.navigateBack());

    final tiles = <CheckboxListTile>{};
    await assistant.scrollDownListView(find.byType(CheckboxListTile),
        onIteration: () => tiles.addAll(assistant.tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))));

    expect(tiles.length, packs.length);
    int index = 0;
    _sortPacks(packs, packOrder).forEach((pack) {
      final checkTile = tiles.elementAt(index++);
      expect((checkTile.title! as OneLineText).content, pack.name);
    });
  }, variant: returnNavigationWayAndOrder);

  final returnNavigationWay = new ValueVariant(
      {ReturnNavigationWay.byOSButton, ReturnNavigationWay.byBarBackButton});
  testWidgets(
      'Updates pack information on the study preparer screen after a card pack is changed during the study',
      (tester) async {
    await _hideStudyDate();

    final packStorage = new PackStorageMock(packsNumber: 7, cardsNumber: 50);
    final assistant = new WidgetAssistant(tester);
    final studyTester = new StudyScreenTester(assistant);

    final packs = await StorageFetcher.fetchNamedPacks(packStorage);
    final packsToStudy = studyTester.takeEnoughCards(packs);
    final cardsToStudy = await StorageFetcher.fetchPackedCards(
        packsToStudy, packStorage.wordStorage);
    final cards = StudyScreenTester.sortCards(cardsToStudy);

    final cardToEdit = cards.first;
    final initialPack = packs.singleWhere((p) => p.id == cardToEdit.packId);
    final initialPackCardsNumber = initialPack.cardsNumber;
    final newPack =
        packs.firstWhere((p) => !p.isNone && p.id != cardToEdit.packId);
    final newPackCardsNumber = newPack.cardsNumber;

    await tester.pumpWidget(RootWidgetMock.buildAsAppHomeWithStudyRouting(
        storage: packStorage, packsToStudy: packsToStudy, noBar: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await assistant.tapWidget(find.widgetWithText(
        ListTile,
        Localizator
            .defaultLocalization.studyPreparerScreenAllCardsCategoryName));

    await studyTester.openEditorMode();

    final editorTester = CardEditorTester(tester);
    await editorTester.changePack(newPack);
    await tester.tap(CardEditorTester.findSaveButton());
    await tester.pumpAndSettle();

    await (returnNavigationWay.currentValue == ReturnNavigationWay.byOSButton
        ? assistant.navigateBackByOSButton()
        : assistant.navigateBack());

    final tiles = <CheckboxListTile>{};
    await assistant.scrollDownListView(find.byType(CheckboxListTile),
        onIteration: () => tiles.addAll(assistant.tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))));

    final initialPackTile = tiles.firstWhere(
        (t) => (t.title! as OneLineText).content == initialPack.name);
    expect((initialPackTile.subtitle as CardNumberIndicator?)?.number,
        initialPackCardsNumber - 1);

    final newPackTile = tiles
        .firstWhere((t) => (t.title! as OneLineText).content == newPack.name);
    expect((newPackTile.subtitle as CardNumberIndicator?)?.number,
        newPackCardsNumber + 1);
  }, variant: returnNavigationWay);

  testWidgets(
      'Updates study progress for a card after its progress is reset during the study',
      (tester) async {
    final packStorage = new PackStorageMock(packsNumber: 7, cardsNumber: 50);
    final assistant = new WidgetAssistant(tester);
    final studyTester = new StudyScreenTester(assistant);

    final packs = await StorageFetcher.fetchNamedPacks(packStorage);
    final packsToStudy = studyTester.takeEnoughCards(packs);
    final cardsToStudy = await StorageFetcher.fetchPackedCards(
        packsToStudy, packStorage.wordStorage);
    final cards = StudyScreenTester.sortCards(cardsToStudy);

    final cardToEdit = cards.first;
    if(cardToEdit.studyProgress == 0)
      await packStorage.wordStorage
            .updateWordProgress(cardToEdit.id!, WordStudyStage.learned);

    await tester.pumpWidget(RootWidgetMock.buildAsAppHomeWithStudyRouting(
        storage: packStorage, packsToStudy: packsToStudy, noBar: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final locale = Localizator.defaultLocalization;
    final unknownStudyStageName = WordStudyStage.stringify(WordStudyStage.unknown, locale);
    var studyStageFinder = find.ancestor(
        of: find.text(unknownStudyStageName, skipOffstage: false),
        matching: find.byType(ListTile, skipOffstage: false));
    final unknownStudyStageTile = tester.widget(studyStageFinder) as ListTile;
    final initialNumberOfUnknownCards = int.parse((unknownStudyStageTile.trailing! as Text).data!); 
    
    await assistant.tapWidget(find.widgetWithText(
        ListTile,
        Localizator
            .defaultLocalization.studyPreparerScreenAllCardsCategoryName));

    await studyTester.openEditorMode();

    await assistant
        .tapWidget(CardEditorTester.findStudyProgressButton(shouldFind: true));
    await tester.tap(CardEditorTester.findSaveButton());
    await tester.pumpAndSettle();

    await (returnNavigationWay.currentValue == ReturnNavigationWay.byOSButton
        ? assistant.navigateBackByOSButton()
        : assistant.navigateBack());

    studyStageFinder = find.ancestor(
        of: find.text(unknownStudyStageName, skipOffstage: false),
        matching: find.byType(ListTile, skipOffstage: false));
    expect(
        find.descendant(
            of: studyStageFinder,
            matching: find.text((initialNumberOfUnknownCards + 1).toString(), skipOffstage: false)),
        findsOneWidget);
  }, variant: returnNavigationWay);

  testWidgets(
      'Updates study progress for a card after its progress is increased during the study',
      (tester) async {
    final packStorage = new PackStorageMock(packsNumber: 7, cardsNumber: 50);
    final assistant = new WidgetAssistant(tester);
    final studyTester = new StudyScreenTester(assistant);

    final packs = await StorageFetcher.fetchNamedPacks(packStorage);
    final packsToStudy = studyTester.takeEnoughCards(packs);
    final cardsToStudy = await StorageFetcher.fetchPackedCards(
        packsToStudy, packStorage.wordStorage);
    final cards = StudyScreenTester.sortCards(cardsToStudy);

    final cardToEdit = cards.first;
    if(cardToEdit.studyProgress > 0)
      await packStorage.wordStorage
            .updateWordProgress(cardToEdit.id!, WordStudyStage.unknown);

    await tester.pumpWidget(RootWidgetMock.buildAsAppHomeWithStudyRouting(
        storage: packStorage, packsToStudy: packsToStudy, noBar: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    final locale = Localizator.defaultLocalization;
    final recognisedStudyStageName = WordStudyStage.stringify(WordStudyStage.recognisedOnce, locale);
    var studyStageFinder = find.ancestor(
        of: find.text(recognisedStudyStageName, skipOffstage: false),
        matching: find.byType(ListTile, skipOffstage: false));
    final recognisedStudyStageTile = tester.widget(studyStageFinder) as ListTile;
    final initialNumberOfRecognisedCards = int.parse((recognisedStudyStageTile.trailing! as Text).data!); 
    
    await assistant.tapWidget(find.widgetWithText(
        ListTile,
        Localizator
            .defaultLocalization.studyPreparerScreenAllCardsCategoryName));

    await assistant.tapWidget(AssuredFinder.findOne(
        label:
            Localizator.defaultLocalization.studyScreenLearningCardButtonLabel,
        type: ElevatedButton,
        shouldFind: true));

    await (returnNavigationWay.currentValue == ReturnNavigationWay.byOSButton
        ? assistant.navigateBackByOSButton()
        : assistant.navigateBack());

    studyStageFinder = find.ancestor(
        of: find.text(recognisedStudyStageName, skipOffstage: false),
        matching: find.byType(ListTile, skipOffstage: false));
    expect(
        find.descendant(
            of: studyStageFinder,
            matching: find.text((initialNumberOfRecognisedCards + 1).toString(), skipOffstage: false)),
        findsOneWidget);
  }, variant: returnNavigationWay);

  testWidgets(
      'Unselects/selects all card packs changing the summary of their study levels',
      (tester) async {
    final storage = await _pumpScreen(tester);

    final packs = await StorageFetcher.fetchNamedPacks(storage);
    final studyPacks = await storage.fetchStudyPacks(null);

    final widgetAssistant = new WidgetAssistant(tester);
    final selectorBtnFinder =
        AssuredFinder.findOne(icon: Icons.select_all, shouldFind: true);
    await widgetAssistant.tapWidget(selectorBtnFinder);

    await _assureConsecutivelyCheckedTiles(tester);
    _assureCardNumbersForStudyLevels(studyPacks, <int>{});

    await widgetAssistant.tapWidget(selectorBtnFinder);

    await _assureConsecutivelyCheckedTiles(tester, packs);
    _assureCardNumbersForStudyLevels(studyPacks);
  });

  testWidgets(
      'Unselects/selects some card packs changing the summary of their study levels',
      (tester) async {
    final storage = await _pumpScreen(tester);

    final studyPacks = await storage.fetchStudyPacks(null);

    final packs = await StorageFetcher.fetchNamedPacks(storage);
    final packsToUncheck = <StoredPack>[packs.first, packs.last];

    final assistant = new WidgetAssistant(tester);

    for (final p in _sortPacksByName(packsToUncheck)) {
      final packTileFinder = await _findPackTile(assistant, p.name);
      await assistant.tapWidget(packTileFinder);
    }

    final uncheckedPackIds = packsToUncheck.map((p) => p.id).toSet();
    final checkedPacks =
        packs.where((p) => !uncheckedPackIds.contains(p.id)).toList();
    await _assureNonConsecutivelyCheckedTiles(tester, checkedPacks);
    _assureCardNumbersForStudyLevels(
        studyPacks, checkedPacks.map((p) => p.id!).toSet());

    final packToCheck = packsToUncheck.last;
    final packTileFinder = await _findPackTile(assistant, packToCheck.name);
    await assistant.tapWidget(packTileFinder);

    checkedPacks.add(packToCheck);
    await _assureNonConsecutivelyCheckedTiles(tester, checkedPacks);
    _assureCardNumbersForStudyLevels(
        studyPacks, checkedPacks.map((p) => p.id!).toSet());
  });

  testWidgets(
      'Scrolls down to the end of the list of study packs and back upwards by clicking the floating button',
      (tester) async {
    final storage = await _pumpScreen(tester, packsNumber: 15, cardsNumber: 50);
    final downwardScrollBtnFinder = _findDownwardScrollBtn(shouldFind: true);

    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(downwardScrollBtnFinder);
    const int animationTimeoutMs = 700;
    await assistant.pumpAndAnimate(animationTimeoutMs);

    final storedPacks =
        _sortPacksByName(await StorageFetcher.fetchNamedPacks(storage));

    final checkTileFinder = _findCheckTiles();
    List<CheckboxListTile> checkTiles =
        tester.widgetList<CheckboxListTile>(checkTileFinder).toList();
    final checkTilesLength = checkTiles.length;

    const itemsToTake = 3;
    int index = itemsToTake;
    storedPacks.skip(storedPacks.length - itemsToTake).forEach((p) {
      final checkTile = checkTiles.elementAt(checkTilesLength - (index--));
      expect((checkTile.title! as OneLineText).content, p.name);
    });

    expect(downwardScrollBtnFinder, findsNothing);

    final upwardScrollBtnFinder = AssuredFinder.findOne(
        icon: Icons.arrow_upward_rounded, shouldFind: true);
    await assistant.tapWidget(upwardScrollBtnFinder);
    await assistant.pumpAndAnimate(animationTimeoutMs);

    index = 0;
    checkTiles = tester.widgetList<CheckboxListTile>(checkTileFinder).toList();
    storedPacks.take(itemsToTake).forEach((p) {
      final checkTile = checkTiles.elementAt(index++);
      expect((checkTile.title! as OneLineText).content, p.name);
    });

    expect(upwardScrollBtnFinder, findsNothing);
    expect(downwardScrollBtnFinder, findsOneWidget);
  });
}

List<StoredPack> _sortPacksByName(List<StoredPack> packs) =>
    _sortPacks(packs, PackOrder.byNameAsc);

List<StoredPack> _sortPacks(List<StoredPack> packs, PackOrder? order) {
  switch (order) {
    case PackOrder.byDateDesc:
    case PackOrder.byDateAsc:
      final direction = order == PackOrder.byDateDesc ? -1 : 1;
      final minDate = new DateTime(1);
      return packs
        ..sort((a, b) {
          final order = direction *
              (a.studyDate ?? minDate).compareTo(b.studyDate ?? minDate);
          return order == 0 ? a.name.compareTo(b.name) : order;
        });
    default:
      final direction = order == PackOrder.byNameDesc ? -1 : 1;
      return packs..sort((a, b) => direction * a.name.compareTo(b.name));
  }
}

Future<PackStorageMock> _pumpScreen(WidgetTester tester,
    {PackStorageMock? storage,
    int? packsNumber,
    int? cardsNumber,
    LanguagePair? langPair}) async {
  storage = storage ??
      new PackStorageMock(packsNumber: packsNumber, cardsNumber: cardsNumber);
  await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
      childBuilder: (context) => new SettingsBlocProvider(
          child: new StudyPreparerScreen(storage, langPair)),
      noBar: true));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));

  return storage;
}

Finder _findCheckTiles() {
  final finder = find.byType(CheckboxListTile, skipOffstage: false);
  expect(finder, findsWidgets);

  return finder;
}

Future<void> _assureConsecutivelyCheckedTiles(WidgetTester tester,
    [List<StoredPack>? checkedPacks,
    void Function(StoredPack, Finder)? tileChecker,
    PackOrder packOrder = PackOrder.byNameAsc]) async {
  if (checkedPacks == null || checkedPacks.isEmpty) {
    expect(
        tester
            .widgetList<CheckboxListTile>(_findCheckTiles())
            .every((t) => t.value!),
        false);
    return;
  }

  final sortedPacks = _sortPacks(checkedPacks, packOrder);

  final checkTiles = _findCheckTiles();
  int index = 0;
  sortedPacks.forEach((p) {
    final packTileFinder = checkTiles.at(index++);
    expect(tester.widget<CheckboxListTile>(packTileFinder).value, true);

    tileChecker?.call(p, packTileFinder);
  });
}

Future<void> _assureNonConsecutivelyCheckedTiles(WidgetTester tester,
    [List<StoredPack>? checkedPacks,
    void Function(StoredPack, Finder)? tileChecker]) async {
  if (checkedPacks == null || checkedPacks.isEmpty) {
    expect(
        tester
            .widgetList<CheckboxListTile>(_findCheckTiles())
            .every((t) => t.value!),
        false);
    return;
  }

  final assistant = new WidgetAssistant(tester);
  final sortedPacks = _sortPacksByName(checkedPacks);

  Finder? packTileFinder = await _findPackTile(
      assistant, sortedPacks.first.name,
      searchUpwards: true);
  for (final p in sortedPacks) {
    packTileFinder ??= await _findPackTile(assistant, p.name);

    expect(tester.widget<CheckboxListTile>(packTileFinder).value, true);

    tileChecker?.call(p, packTileFinder);

    packTileFinder = null;
  }
}

Future<Finder> _findPackTile(WidgetAssistant assistant, String packName,
    {bool searchUpwards = false}) async {
  final packTileFinder = find.ancestor(
      of: find.text(packName), matching: find.byType(CheckboxListTile));
  final visibleFinder = await assistant.scrollUntilVisible(
      packTileFinder, CheckboxListTile,
      upwards: searchUpwards);
  expect(visibleFinder, findsOneWidget);
  return visibleFinder;
}

void _assureCardNumbersForStudyLevels(Iterable<StudyPack> studyPacks,
    [Set<int>? includedPackIds]) {
  final studyStages = <int, int>{for (final v in WordStudyStage.values) v: 0};

  Iterable<StudyPack> stPacks = studyPacks;
  if (includedPackIds != null)
    stPacks = stPacks.where((p) => includedPackIds.contains(p.pack.id));

  stPacks
      .expand((e) => e.cardsByStage.entries)
      .forEach((en) => studyStages[en.key] = studyStages[en.key]! + en.value);

  final locale = Localizator.defaultLocalization;
  final levels = <String, int>{};
  studyStages.entries.forEach((en) {
    final key = WordStudyStage.stringify(en.key, locale);
    if (levels.containsKey(key))
      levels[key] = levels[key]! + en.value;
    else
      levels[key] = en.value;
  });
  levels[locale.studyPreparerScreenAllCardsCategoryName] =
      levels.values.reduce((res, el) => res + el);

  levels.forEach((lvl, cardNumber) {
    final levelFinder = find.ancestor(
        of: find.text(lvl, skipOffstage: false),
        matching: find.byType(ListTile, skipOffstage: false));
    expect(levelFinder, findsOneWidget);
    expect(
        find.descendant(
            of: levelFinder,
            matching: find.text(cardNumber.toString(), skipOffstage: false)),
        findsOneWidget);
  });
}

Finder _findDownwardScrollBtn({bool? shouldFind}) => AssuredFinder.findOne(
    icon: Icons.arrow_downward_rounded, shouldFind: shouldFind ?? false);

Future<void> _testRenderingStudyDates(WidgetTester tester,
    {bool shouldShowDates = false}) async {
  final storage = await _pumpScreen(tester);

  final packs = await StorageFetcher.fetchNamedPacks(storage);
  expect(_findCheckTiles(), findsNWidgets(packs.length));

  final locale = Localizator.defaultLocalization;
  await _assureConsecutivelyCheckedTiles(tester, packs, (p, packTileFinder) {
    if (p.studyDate == null)
      expect(find.descendant(of: packTileFinder, matching: find.byType(Column)),
          findsNothing);
    else
      expect(
          find.descendant(
              of: packTileFinder,
              matching: find.text(locale.studyPreparerScreenPackLastStudyDate(
                  DateFormat.yMMMMd(locale.localeName).format(p.studyDate!)))),
          shouldShowDates ? findsOneWidget : findsNothing);
  });
}

Future<void> _setPackOrderPreference(PackOrder? order) async {
  final userParams = await PreferencesProvider.fetch();
  userParams.studyParams.packOrder = order;
  await PreferencesTester.saveParams(userParams);
}

Future<void> _hideStudyDate() async {
  final userParams = await PreferencesProvider.fetch();
  userParams.studyParams.showStudyDate = false;
  await PreferencesTester.saveParams(userParams);
}

Future<void> _testRenderingPackOrder(
    WidgetTester tester, PackOrder order) async {
  final storage = await _pumpScreen(tester);
  final packs = await StorageFetcher.fetchNamedPacks(storage);

  await _assureConsecutivelyCheckedTiles(tester, packs, (p, packTileFinder) {
    expect(find.descendant(of: packTileFinder, matching: find.text(p.name)),
        findsOneWidget);
  }, order);
}
