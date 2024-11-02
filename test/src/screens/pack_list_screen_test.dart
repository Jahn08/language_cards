import 'package:flutter/material.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/blocs/settings_bloc.dart';
import 'package:language_cards/src/consts.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/router.dart';
import 'package:language_cards/src/screens/list_screen.dart';
import 'package:language_cards/src/screens/main_screen.dart';
import 'package:language_cards/src/screens/pack_list_screen.dart';
import 'package:language_cards/src/utilities/pack_exporter.dart';
import 'package:language_cards/src/widgets/card_number_indicator.dart';
import 'package:language_cards/src/widgets/translation_indicator.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/context_channel_mock.dart';
import '../../mocks/permission_channel_mock.dart';
import '../../mocks/root_widget_mock.dart';
import '../../mocks/word_storage_mock.dart';
import '../../testers/dialog_tester.dart';
import '../../testers/exporter_tester.dart';
import '../../testers/language_pair_selector_tester.dart';
import '../../testers/list_screen_tester.dart';
import '../../testers/preferences_tester.dart';
import '../../testers/selector_dialog_tester.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/variants.dart';
import '../../utilities/widget_assistant.dart';

void main() {
  final screenTester = new ListScreenTester('Pack',
      ([packsNumber]) => _buildPackListScreen(packsNumber: packsNumber));
  screenTester.testEditorMode();
  screenTester.testSearchMode(PackStorageMock.generatePack);

  screenTester.testDismissingItems();

  testWidgets("Renders packs filtered by a language pair", (tester) async {
    final storage = new PackStorageMock(singleLanguagePair: false);
    final langPairs = await storage.fetchLanguagePairs();
    final chosenLangPair = langPairs.first;

    await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
        child: new PackListScreen(
            storage: storage,
            cardStorage: storage.wordStorage,
            languagePair: chosenLangPair)));
    final assistant = new WidgetAssistant(tester);
    await assistant.pumpAndAnimate();

    final langPairPacks = await storage.fetch(languagePair: chosenLangPair);
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

  final returnNavigationWay =
      ValueVariant<ReturnNavigationWay>(ReturnNavigationWay.values.toSet());

  testWidgets(
      "Removes a language pair from the language pair selector after all its packs were removed",
      (tester) async {
    await PreferencesTester.saveDefaultUserParams();

    final storage = await _pumpScreenWithRouting(tester,
        mainScreenBuilder: (PackStorage? storage) =>
            new SettingsBlocProvider(child: MainScreen(packStorage: storage)),
        singleLanguagePair: false);

    final langPairs = await storage.fetchLanguagePairs();
    final langPairPacks = await storage.fetch(languagePair: langPairs.first);
    final langPairPackNames = langPairPacks.map((p) => p.name).toList();

    final assistant = new WidgetAssistant(tester);
    await screenTester.activateEditorMode(assistant);
    await screenTester.selectItemsInEditor(assistant, langPairPackNames);
    await screenTester.deleteSelectedItems(assistant, shouldAccept: true);

    await _goBack(assistant, returnNavigationWay.currentValue!);

    LanguagePairSelectorTester.findEmptyPairSelector(shouldFind: false);
    LanguagePairSelectorTester.findNonEmptyPairSelector(shouldFind: false);
  }, variant: returnNavigationWay);

  testWidgets(
      "Updates a pack with a new language pair which should appear in the language pair selector",
      (tester) async {
    await PreferencesTester.saveDefaultUserParams();

    final storage = await _pumpScreenWithRouting(tester,
        mainScreenBuilder: (PackStorage? storage) =>
            new SettingsBlocProvider(child: MainScreen(packStorage: storage)),
        singleLanguagePair: false);

    final langPairs = await storage.fetchLanguagePairs();
    final fromLanguages = langPairs.map((p) => p.from).toSet();
    final toLanguages = langPairs.map((p) => p.to).toSet();
    final langToChoose = Language.values.firstWhere(
        (l) => !fromLanguages.contains(l) && !toLanguages.contains(l));

    final packToEdit = await _getFirstPackWithEnoughCards(storage, tester);
    final assistant = new WidgetAssistant(tester);
    await _goToPack(assistant, packToEdit.name);

    await assistant.changeDropdownItem(packToEdit.from!, langToChoose);

    final saveBtn = find.widgetWithText(ElevatedButton,
        Localizator.defaultLocalization.constsSavingItemButtonLabel);
    await assistant.tapWidget(saveBtn);

    await _goBack(assistant, returnNavigationWay.currentValue!);

    await assistant
        .tapWidget(LanguagePairSelectorTester.findEmptyPairSelector());

    SelectorDialogTester.assureRenderedOptions(
        tester,
        LanguagePairSelectorTester.prepareLanguagePairsForDisplay(
            langPairs..add(new LanguagePair(langToChoose, packToEdit.to!)),
            Localizator.defaultLocalization), (finder, pair) {
      final option = tester.widget<SimpleDialogOption>(finder);

      final optionTile = option.child! as ListTile;
      final pairIndicator = optionTile.title! as TranslationIndicator;

      if (!pair.isEmpty) {
        expect(pairIndicator.from, pair.from);
        expect(pairIndicator.to, pair.to);
      }
    }, ListTile);
  }, variant: returnNavigationWay);

  testWidgets(
      "Imports a pack with a new language pair which should appear in the language pair selector",
      (tester) async {
    await PreferencesTester.saveDefaultUserParams();

    final storage = await _pumpScreenWithRouting(tester,
        mainScreenBuilder: (PackStorage? storage) =>
            new SettingsBlocProvider(child: MainScreen(packStorage: storage)),
        singleLanguagePair: false);

    final langPairs = await storage.fetchLanguagePairs();
    final fromLanguages = langPairs.map((p) => p.from).toSet();
    final toLanguages = langPairs.map((p) => p.to).toSet();

    final expectedFromLang = Language.values.firstWhere(
        (l) => !fromLanguages.contains(l) && !toLanguages.contains(l));
    final packToImport =
        PackStorageMock.generatePack(99, from: expectedFromLang);

    final assistant = new WidgetAssistant(tester);

    await ContextChannelMock.testWithChannel(() async {
      final importFilePath = await tester.runAsync(() =>
          new PackExporter(storage.wordStorage).export([packToImport],
              Randomiser.nextString(), Localizator.defaultLocalization));

      await screenTester.activateEditorMode(assistant);

      await _activateImport(assistant, importFilePath!);
      await assistant.tapWidget(DialogTester.findConfirmationDialogBtn());
    });

    await _goBack(assistant, returnNavigationWay.currentValue!);
    await assistant
        .tapWidget(LanguagePairSelectorTester.findEmptyPairSelector());

    SelectorDialogTester.assureRenderedOptions(
        tester,
        LanguagePairSelectorTester.prepareLanguagePairsForDisplay(
            langPairs
              ..add(new LanguagePair(packToImport.from!, packToImport.to!)),
            Localizator.defaultLocalization), (finder, pair) {
      final option = tester.widget<SimpleDialogOption>(finder);

      final optionTile = option.child! as ListTile;
      final pairIndicator = optionTile.title! as TranslationIndicator;

      if (!pair.isEmpty) {
        expect(pairIndicator.from, pair.from);
        expect(pairIndicator.to, pair.to);
      }
    }, ListTile);
  }, variant: returnNavigationWay);

  testWidgets(
      "Updates a pack in the pack list, after going to its cards and back to the card list",
      (tester) async {
    final storage = await _pumpScreenWithRouting(tester);

    final packToEdit = await _getFirstPackWithEnoughCards(storage, tester);

    final assistant = new WidgetAssistant(tester);
    await _goToPack(assistant, packToEdit.name);

    final newPackName = await assistant.enterChangedText(packToEdit.name);
    await assistant.finishEnteringText();

    final saveAndAddBtn = find.widgetWithText(
        ElevatedButton,
        Localizator
            .defaultLocalization.packScreenSavingAndAddingCardsButtonLabel);
    await assistant.tapWidget(saveAndAddBtn);

    await _goBackToPackList(
        assistant, newPackName, returnNavigationWay.currentValue!);

    final tileWithCardsFinder = find.ancestor(
        of: find.text(newPackName), matching: find.byType(ListTile));
    expect(tileWithCardsFinder, findsOneWidget);
  }, variant: returnNavigationWay);

  final returnNavigationWayAndPack =
      new ValueVariant<DoubleVariant<ReturnNavigationWay, bool>>({
    new DoubleVariant(ReturnNavigationWay.byOSButton, true, name2: "nonePack"),
    new DoubleVariant(ReturnNavigationWay.byBarBackButton, true,
        name2: "nonePack"),
    new DoubleVariant(ReturnNavigationWay.byOSButton, false,
        name2: "namedPack"),
    new DoubleVariant(ReturnNavigationWay.byBarBackButton, false,
        name2: "namedPack")
  });

  testWidgets(
      "Doesn't update a number of cards for a pack without changes in it",
      (tester) async {
    final storage = await _pumpScreenWithRouting(tester);

    final isNonePack = returnNavigationWayAndPack.currentValue!.value2;
    final packWithCards = await (isNonePack
        ? _getNonePack(storage, tester)
        : _getFirstPackWithEnoughCards(storage, tester));

    final expectedNumberOfCards = packWithCards.cardsNumber;

    final assistant = new WidgetAssistant(tester);

    final packName = packWithCards.name;
    await _goToCardList(assistant, packName);

    expect(find.byType(Dismissible), findsNWidgets(expectedNumberOfCards));

    final returnNavigationWay = returnNavigationWayAndPack.currentValue!.value1;
    await _goBackToPackList(assistant, packName, returnNavigationWay);

    await _assertPackCardNumber(
        tester, storage, packWithCards, expectedNumberOfCards);
  }, variant: returnNavigationWayAndPack);

  testWidgets("Decreases a number of cards for a pack after deleting one",
      (tester) async {
    final storage = await _pumpScreenWithRouting(tester);

    final isNonePack = returnNavigationWayAndPack.currentValue!.value2;
    final packWithCards = await (isNonePack
        ? _getNonePack(storage, tester)
        : _getFirstPackWithEnoughCards(storage, tester));

    final expectedNumberOfCards = packWithCards.cardsNumber - 1;

    final assistant = new WidgetAssistant(tester);
    await _goToCardList(assistant, packWithCards.name);

    await assistant.swipeWidgetLeft(find.byType(Dismissible).first);

    final returnNavigationWay = returnNavigationWayAndPack.currentValue!.value1;
    await _goBackToPackList(assistant, packWithCards.name, returnNavigationWay);

    await _assertPackCardNumber(
        tester, storage, packWithCards, expectedNumberOfCards);
  }, variant: returnNavigationWayAndPack);

  testWidgets("Increases a number of cards for a pack after adding one",
      (tester) async {
    final storage = await _pumpScreenWithRouting(tester, cardWasAdded: true);

    final isNonePack = returnNavigationWayAndPack.currentValue!.value2;
    final packWithCards = await (isNonePack
        ? _getNonePack(storage, tester)
        : _getFirstPackWithEnoughCards(storage, tester));
    final expectedNumberOfCards = packWithCards.cardsNumber + 1;

    final assistant = new WidgetAssistant(tester);
    await _goToCardList(assistant, packWithCards.name);

    await tester.runAsync(() async {
      final randomWord = WordStorageMock.generateWord(
          packId: packWithCards.id, hasNoPack: packWithCards.isNone);
      await storage.wordStorage.upsert([randomWord]);
    });

    final returnNavigationWay = returnNavigationWayAndPack.currentValue!.value1;
    await _goBackToPackList(assistant, packWithCards.name, returnNavigationWay);

    await _assertPackCardNumber(
        tester, storage, packWithCards, expectedNumberOfCards);
  }, variant: returnNavigationWayAndPack);

  testWidgets("Renders an unremovable link for a list of cards without a pack",
      (tester) async {
    await screenTester.pumpScreen(tester);
    _findPackTileByName(_nonePackName);

    await screenTester.activateEditorMode(new WidgetAssistant(tester));
    _findPackTileByName(_nonePackName);
  });

  testWidgets(
      "Deletes packs with cards and increases the number of cards without a pack",
      (tester) async {
    final storage =
        await screenTester.pumpScreen(tester, null, 5) as PackStorageMock;

    final assistant = new WidgetAssistant(tester);
    await screenTester.activateEditorMode(assistant);

    final tilesToDelete = await screenTester.selectSomeItemsInEditor(assistant);
    final packToDeleteNames = tilesToDelete.values.toSet();

    final packs = await _fetchPacks(storage, tester);
    final packsToDelete =
        packs.where((p) => packToDeleteNames.contains(p.name));

    final untiedCardsCount =
        packsToDelete.fold<int>(0, (res, i) => res + i.cardsNumber);

    final nonePack = await _getNonePack(storage, tester);
    final nonePacksNumber = nonePack.cardsNumber;

    await screenTester.deleteSelectedItems(assistant, shouldAccept: true);
    await screenTester.deactivateEditorMode(assistant);

    await _assertPackCardNumber(
        tester, storage, nonePack, nonePacksNumber + untiedCardsCount);
  });

  testWidgets(
      "Doesn't increase the number of cards without a pack when cancelling their pack deletion",
      (tester) async {
    final storage =
        await screenTester.pumpScreen(tester, null, 3) as PackStorageMock;

    final assistant = new WidgetAssistant(tester);
    await screenTester.activateEditorMode(assistant);

    await screenTester.selectSomeItemsInEditor(assistant);

    final nonePack = await _getNonePack(storage, tester);
    final nonePacksNumber = nonePack.cardsNumber;

    await screenTester.deleteSelectedItems(assistant, shouldCancel: true);
    await screenTester.deactivateEditorMode(assistant);

    await _assertPackCardNumber(tester, storage, nonePack, nonePacksNumber);
  });

  testWidgets("Doesn't show warning when removing a pack without cards",
      (tester) async {
    final packWithoutCards =
        PackStorageMock.generatePack(Randomiser.nextInt(100) + 99);
    await screenTester.pumpScreen(tester, (st) async {
      final storage = st as PackStorageMock;

      await tester.runAsync(() => storage.upsert([packWithoutCards]));
    });

    final assistant = new WidgetAssistant(tester);
    await screenTester.activateEditorMode(assistant);

    await screenTester.selectItemsInEditor(assistant, [packWithoutCards.name]);

    await screenTester.deleteSelectedItems(assistant, shouldNotWarn: true);
  });

  testWidgets(
      "Changes the export/import action when selecting/unselecting packs respectively",
      (tester) async {
    await screenTester.pumpScreen(tester);

    final assistant = new WidgetAssistant(tester);
    await screenTester.activateEditorMode(assistant);

    _findImportExportAction(shouldFind: true);
    _findImportExportAction(isExport: true, shouldFind: false);

    await screenTester.selectSomeItemsInEditor(assistant);

    _findImportExportAction(isExport: true, shouldFind: true);
    _findImportExportAction(shouldFind: false);
  });

  testWidgets(
      "Exports selected packs into a JSON-file and shows its path thereafter",
      (tester) async {
    final storage = await screenTester.pumpScreen(tester) as PackStorageMock;

    final assistant = new WidgetAssistant(tester);
    await screenTester.activateEditorMode(assistant);
    final selectedPackNames =
        (await screenTester.selectSomeItemsInEditor(assistant)).values.toSet();
    final packsToExport = (await _fetchPacks(storage, tester))
        .where((p) => selectedPackNames.contains(p.name))
        .toList();

    await ContextChannelMock.testWithChannel(() async {
      final exportBtnFinder =
          _findImportExportAction(isExport: true, shouldFind: true);
      await assistant.tapWidget(exportBtnFinder);

      final exportFilePath =
          _findConfirmationDialogText(tester).split(' ').last;
      final exporterTester = new ExporterTester(exportFilePath);
      exporterTester.assertExportFileName('packs');

      await tester.runAsync(
          () => exporterTester.assertExportedPacks(storage, packsToExport));
    });
  });

  testWidgets(
      "Warns about having no permissions for export when a user denies the access",
      (tester) async {
    final storage = await screenTester.pumpScreen(tester) as PackStorageMock;

    final assistant = new WidgetAssistant(tester);
    await screenTester.activateEditorMode(assistant);
    final selectedPacNames =
        (await screenTester.selectSomeItemsInEditor(assistant)).values.toSet();
    (await _fetchPacks(storage, tester))
        .where((p) => selectedPacNames.contains(p.name))
        .toList();

    await ContextChannelMock.testWithChannel(
        () async => PermissionChannelMock.testWithChannel(() async {
              final exportBtnFinder =
                  _findImportExportAction(isExport: true, shouldFind: true);
              await assistant.tapWidget(exportBtnFinder);

              final exportFailureInfo = _findConfirmationDialogText(tester);
              expect(exportFailureInfo.contains('permissions'), true);
            }, noPermissionsByDefault: true, shouldDenyPermissions: true),
        arePermissionsRequired: true);
  });

  testWidgets(
      "Exports selected packs into a JSON-file when a user grants necessary permissions for it",
      (tester) async {
    final storage = await screenTester.pumpScreen(tester) as PackStorageMock;

    final assistant = new WidgetAssistant(tester);
    await screenTester.activateEditorMode(assistant);
    final selectedPackNames =
        (await screenTester.selectSomeItemsInEditor(assistant)).values.toSet();
    final packsToExport = (await _fetchPacks(storage, tester))
        .where((p) => selectedPackNames.contains(p.name))
        .toList();

    await ContextChannelMock.testWithChannel(
        () => PermissionChannelMock.testWithChannel(() async {
              final exportBtnFinder =
                  _findImportExportAction(isExport: true, shouldFind: true);
              await assistant.tapWidget(exportBtnFinder);

              final exportFilePath =
                  _findConfirmationDialogText(tester).split(' ').last;
              final exporterTester = new ExporterTester(exportFilePath);
              exporterTester.assertExportFileName('packs');

              await tester.runAsync(() =>
                  exporterTester.assertExportedPacks(storage, packsToExport));
            }, noPermissionsByDefault: true),
        arePermissionsRequired: true);
  });

  testWidgets(
      "Warns about a non-existent file when trying to import packs from it",
      (tester) async {
    await screenTester.pumpScreen(tester);
    final assistant = new WidgetAssistant(tester);

    await screenTester.activateEditorMode(assistant);

    final importFilePath = Randomiser.nextString() + '.json';
    await _activateImport(assistant, importFilePath);

    final importInfo = _findConfirmationDialogText(tester);
    final locale = Localizator.defaultLocalization;
    expect(
        importInfo.contains(locale
            .packListScreenImportDialogWrongFormatContent(importFilePath)),
        true);
  });

  testWidgets(
      "Warns about a file of an incorrect format when trying to import packs from it",
      (tester) async {
    await screenTester.pumpScreen(tester);

    final assistant = new WidgetAssistant(tester);
    await screenTester.activateEditorMode(assistant);

    await ContextChannelMock.testWithChannel(() async {
      final importFilePath = ExporterTester.writeToJsonFile([
        Randomiser.nextInt(),
        Randomiser.nextString(),
        Randomiser.nextInt()
      ]);
      await _activateImport(assistant, importFilePath);

      final importInfo = _findConfirmationDialogText(tester);
      final locale = Localizator.defaultLocalization;
      expect(
          importInfo.contains(locale
              .packListScreenImportDialogWrongFormatContent(importFilePath)),
          true);
    });
  });

  testWidgets(
      "Imports packs from a JSON-file and shows the newly added packs with the result of the operation",
      (tester) async {
    final storage = await screenTester.pumpScreen(tester) as PackStorageMock;
    final assistant = new WidgetAssistant(tester);

    await _testImportingPacks(assistant, storage, screenTester);

    await screenTester.deactivateEditorMode(assistant);
  });

  testWidgets(
      "Imports packs, adds a new search index and goes to the default search index",
      (tester) async {
    final storage = new PackStorageMock();
    final inScreenTester = _buildScreenTester(storage);

    final indexes = await inScreenTester.testSwitchingToSearchMode(tester,
        newEntityGetter: PackStorageMock.generatePack,
        shouldKeepInSearchMode: true);

    final activeIndex = indexes.first;
    final assistant = new WidgetAssistant(tester);
    await inScreenTester.chooseFilterIndex(assistant, activeIndex);

    final exportedPacks =
        await _testImportingPacks(assistant, storage, inScreenTester);
    await assistant.pumpAndAnimate(500);

    inScreenTester.findSearcherEndButton(shouldFind: true);

    final newIndexes =
        (indexes..addAll(exportedPacks.map((p) => p.name[0].toUpperCase())));
    inScreenTester.assureFilterIndexes(newIndexes, shouldFind: true);

    inScreenTester.assureFilterIndexActiveness(tester, activeIndex);

    await inScreenTester.deactivateSearcherMode(assistant);

    await inScreenTester.deactivateEditorMode(assistant);
  });

  testWidgets(
      'Selects all existent packs even if there are more than should be available by default',
      (tester) async {
    final itemsOverall = (ListScreen.itemsPerPage * 1.25).toInt();
    final storage = new PackStorageMock(packsNumber: itemsOverall);
    final inScreenTester = _buildScreenTester(storage);
    await inScreenTester.pumpScreen(tester);

    final assistant = new WidgetAssistant(tester);
    await inScreenTester.activateEditorMode(assistant);
    await inScreenTester.selectAll(assistant);

    final selectorLabel = inScreenTester.getSelectorBtnLabel(tester);
    expect(
        selectorLabel,
        Localizator.defaultLocalization
            .constsUnselectAll(itemsOverall.toString()));

    await assistant.scrollDownListView(find.byType(CheckboxListTile),
        iterations: 25);
    final updatedSelectorLabel = inScreenTester.getSelectorBtnLabel(tester);
    expect(selectorLabel, updatedSelectorLabel);

    inScreenTester.assureSelectionForAllTilesInEditor(tester, selected: true);
  });
}

PackListScreen _buildPackListScreen(
    {PackStorageMock? storage, int? packsNumber, bool refresh = false}) {
  storage ??= new PackStorageMock(
      packsNumber: packsNumber ?? 40,
      textGetter: (text, id) => (id! % 2).toString() + text);
  return new PackListScreen(
      storage: storage, cardStorage: storage.wordStorage, refresh: refresh);
}

Future<PackStorageMock> _pumpScreenWithRouting(WidgetTester tester,
    {bool? cardWasAdded,
    Widget Function(PackStorage?)? mainScreenBuilder,
    bool singleLanguagePair = true}) async {
  final storage = new PackStorageMock(singleLanguagePair: singleLanguagePair);
  await tester.pumpWidget(RootWidgetMock.buildAsAppHomeWithNonStudyRouting(
      storage: storage,
      mainScreenBuilder: mainScreenBuilder,
      packListScreenBuilder: (PackListRoute? route) => _buildPackListScreen(
          storage: storage, refresh: route?.params.refresh == true),
      cardWasAdded: cardWasAdded));

  await tester.pump(const Duration(milliseconds: 500));

  final finder = find.byIcon(Consts.packListIcon);
  await new WidgetAssistant(tester).tapWidget(finder);

  return storage;
}

Future<StoredPack> _getFirstPackWithEnoughCards(
        PackStorageMock storage, WidgetTester tester) async =>
    (await _fetchPacks(storage, tester)).firstWhere((p) =>
        p.cardsNumber > 0 && p.cardsNumber < 8 && p.name != _nonePackName);

Future<List<StoredPack>> _fetchPacks(
        PackStorageMock storage, WidgetTester tester) async =>
    (await tester.runAsync<List<StoredPack>>(() => storage.fetch()))!;

Future<void> _goToCardList(WidgetAssistant assistant, String packName) async {
  await _goToPack(assistant, packName);

  if (packName == _nonePackName) return;

  final cardListBtnFinder = find.byIcon(Icons.filter_1);
  expect(cardListBtnFinder, findsOneWidget);
  await assistant.tapWidget(cardListBtnFinder);
}

Future<void> _goToPack(WidgetAssistant assistant, String packName) {
  final tileWithCardsFinder = _findPackTileByName(packName);
  expect(tileWithCardsFinder, findsOneWidget);
  return assistant.tapWidget(tileWithCardsFinder);
}

Finder _findPackTileByName(String name) {
  final packTileFinder = find.ancestor(
      of: find.text(name), matching: find.byType(ListTile), matchRoot: true);
  expect(packTileFinder, findsOneWidget);

  return packTileFinder;
}

Future<void> _goBackToPackList(WidgetAssistant assistant, String packName,
    ReturnNavigationWay returnNavigationWay) async {
  await _goBack(assistant, returnNavigationWay);

  if (packName == _nonePackName) return;

  await _goBack(assistant, returnNavigationWay);
}

Future<void> _goBack(
        WidgetAssistant assistant, ReturnNavigationWay returnNavigationWay) =>
    returnNavigationWay == ReturnNavigationWay.byOSButton
        ? assistant.navigateBackByOSButton()
        : assistant.navigateBack();

Future<void> _assertPackCardNumber(WidgetTester tester, PackStorageMock storage,
    StoredPack pack, int expectedNumber) async {
  final tileWithCardsFinder =
      find.ancestor(of: find.text(pack.name), matching: find.byType(ListTile));
  expect(tileWithCardsFinder, findsOneWidget);

  expect(
      find.descendant(
          of: tileWithCardsFinder,
          matching: find.text(Localizator.defaultLocalization
              .cardNumberIndicatorContent(expectedNumber.toString()))),
      findsOneWidget);

  await tester.runAsync(() async {
    final actualPackWithCards = pack.id == null
        ? (await storage.fetch()).first
        : await storage.find(pack.id);
    expect(actualPackWithCards?.cardsNumber, expectedNumber);
  });
}

Future<StoredPack> _getNonePack(
        PackStorageMock storage, WidgetTester tester) async =>
    (await _fetchPacks(storage, tester))
        .firstWhere((p) => p.name == _nonePackName);

Future<List<StoredPack>> _testImportingPacks(WidgetAssistant assistant,
    PackStorageMock storage, ListScreenTester screenTester) async {
  final tester = assistant.tester;
  final packsToExport = ExporterTester.getPacksForExport(storage);
  final existentPackIds =
      (await tester.runAsync(() => storage.fetch()))!.map((p) => p.id).toSet();

  await ContextChannelMock.testWithChannel(() async {
    final importFilePath = await tester.runAsync(() =>
        new PackExporter(storage.wordStorage).export(packsToExport,
            Randomiser.nextString(), Localizator.defaultLocalization));

    await screenTester.activateEditorMode(assistant);

    await _activateImport(assistant, importFilePath!);

    final importInfo = _findConfirmationDialogText(tester);
    expect(importInfo.contains(packsToExport.length.toString()), true);
    expect(importInfo.contains(importFilePath), true);

    final storedCards = await tester.runAsync(() => storage.wordStorage
        .fetchFiltered(parentIds: packsToExport.map((p) => p.id).toList()));
    expect(importInfo.contains(storedCards!.length.toString()), true,
        reason:
            'A message "$importInfo" does not contain the number of imported packs=${storedCards.length}');

    await assistant.tapWidget(DialogTester.findConfirmationDialogBtn());

    for (final packToExport in packsToExport
      ..sort((a, b) => a.name.compareTo(b.name))) {
      await assistant.scrollUntilVisible(
          find.text(packToExport.name), CheckboxListTile);

      final isDuplicatedPack = existentPackIds.contains(packToExport.id);
      String expectedImportedPackName = packToExport.name;
      if(isDuplicatedPack) {
        expect(find.text(packToExport.name, skipOffstage: false), findsOne);
        expectedImportedPackName += "_imported";
      }

      final packNameFinder = find.text(expectedImportedPackName, skipOffstage: false);
      expect(packNameFinder, findsOne);

      final packTileFinders = find.ancestor(
          of: packNameFinder,
          matching: find.byType(CheckboxListTile, skipOffstage: false));
      expect(packTileFinders, findsOne);

      final cardsNumberIndicators = tester.widgetList<CardNumberIndicator>(
          find.descendant(
              of: packTileFinders,
              matching: find.byType(CardNumberIndicator, skipOffstage: false)));
      cardsNumberIndicators
          .forEach((i) => i.number == packToExport.cardsNumber);

      final langIndicators = tester.widgetList<TranslationIndicator>(
          find.descendant(
              of: packTileFinders,
              matching:
                  find.byType(TranslationIndicator, skipOffstage: false)));
      langIndicators.forEach((i) {
        expect(i.from, packToExport.from);
        expect(i.to, packToExport.to);
      });
    }
  });

  return packsToExport;
}

Future<void> _activateImport(
    WidgetAssistant assistant, String importFilePath) async {
  final importBtnFinder = _findImportExportAction(shouldFind: true);
  await assistant.tapWidget(importBtnFinder);

  final filePathTxtFinder =
      AssuredFinder.findOne(type: TextField, shouldFind: true);
  await assistant.tester.enterText(filePathTxtFinder, importFilePath);

  final importConfirmationBtnFinder = find.widgetWithText(ElevatedButton,
      Localizator.defaultLocalization.importDialogImportBtnLabel);
  await assistant.tapWidget(importConfirmationBtnFinder);
}

Finder _findImportExportAction({bool isExport = false, bool? shouldFind}) {
  final locale = Localizator.defaultLocalization;
  return AssuredFinder.findOne(
      icon: Icons.import_export,
      label: isExport
          ? locale.packListScreenBottomNavBarExportActionLabel
          : locale.packListScreenBottomNavBarImportActionLabel,
      shouldFind: shouldFind);
}

String _findConfirmationDialogText(WidgetTester tester) {
  final dialog = DialogTester.findConfirmationDialog(tester);
  return tester
      .widget<Text>(find.descendant(
          of: find.byWidget(dialog.content!), matching: find.byType(Text)))
      .data!;
}

ListScreenTester<StoredPack> _buildScreenTester(PackStorageMock storage) =>
    new ListScreenTester<StoredPack>(
        'Pack', ([_]) => _buildPackListScreen(storage: storage));

String get _nonePackName => StoredPack.none.name;
