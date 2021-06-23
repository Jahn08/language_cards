import 'package:flutter/material.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/router.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/screens/card_list_screen.dart';
import 'package:language_cards/src/screens/main_screen.dart';
import 'package:language_cards/src/screens/pack_screen.dart';
import 'package:language_cards/src/screens/pack_list_screen.dart';
import 'package:language_cards/src/models/app_params.dart';
import 'package:language_cards/src/utilities/pack_exporter.dart';
import 'package:language_cards/src/widgets/card_number_indicator.dart';
import 'package:language_cards/src/widgets/translation_indicator.dart';
import '../../mocks/dictionary_provider_mock.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/root_widget_mock.dart';
import '../../mocks/word_storage_mock.dart';
import '../../testers/dialog_tester.dart';
import '../../testers/exporter_tester.dart';
import '../../testers/list_screen_tester.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/fake_path_provider_platform.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/widget_assistant.dart';

void main() {
    final screenTester = new ListScreenTester('Pack', 
		([packsNumber]) => _buildPackListScreen(packsNumber: packsNumber));
    screenTester.testEditorMode();
    screenTester.testSearchMode(PackStorageMock.generatePack);

	screenTester.testDismissingItems();

    testWidgets("Doesn't update a number of cards for a pack without changes in it", (tester) async {
        final storage = await _pumpScreenWithRouting(tester);

        final packWithCards = await _getFirstPackWithEnoughCards(storage, tester);
        await _testShowingCardsWithoutChanging(tester, storage, packWithCards);
    });

    testWidgets("Decreases a number of cards for a pack after deleting one", (tester) async {
        final storage = await _pumpScreenWithRouting(tester);

        final packWithCards = await _getFirstPackWithEnoughCards(storage, tester);
        await _testDecreasingNumberOfCards(tester, storage, packWithCards);
    });

    testWidgets("Increases a number of cards for a pack after adding one", (tester) async {
        final storage = await _pumpScreenWithRouting(tester, cardWasAdded: true);

        final packWithCards = await _getFirstPackWithEnoughCards(storage, tester);
        await _testIncreasingNumberOfCards(tester, storage, packWithCards);
    });

    testWidgets("Renders an unremovable link for a list of cards without a pack", (tester) async {
        await screenTester.pumpScreen(tester);
        _findPackTileByName(StoredPack.noneName);

        await screenTester.activateEditorMode(new WidgetAssistant(tester));
        _findPackTileByName(StoredPack.noneName);
    });

    testWidgets("Doesn't update a number of cards for the none pack without changes in it", (tester) async {
        final storage = await _pumpScreenWithRouting(tester);

        final nonePack = await _getNonePack(storage, tester);
        await _testShowingCardsWithoutChanging(tester, storage, nonePack);
    });

    testWidgets("Decreases a number of cards for the none pack after deleting one", (tester) async {
        final storage = await _pumpScreenWithRouting(tester);

        final nonePack = await _getNonePack(storage, tester);
        await _testDecreasingNumberOfCards(tester, storage, nonePack);
    });

    testWidgets("Increases a number of cards for the none pack after adding one", (tester) async {
        final storage = await _pumpScreenWithRouting(tester, cardWasAdded: true);

        final nonePack = await _getNonePack(storage, tester);
        await _testIncreasingNumberOfCards(tester, storage, nonePack);
    });

	testWidgets("Deletes packs with cards and increases the number of cards without a pack", 
		(tester) async {
			final storage = await screenTester.pumpScreen(tester, null, 5) as PackStorageMock;

			final assistant = new WidgetAssistant(tester);
			await screenTester.activateEditorMode(assistant);
			
			final tilesToDelete = await screenTester.selectSomeItemsInEditor(assistant);
			final packToDeleteNames = tilesToDelete.values;

			final packs = await _fetchPacks(storage, tester);
			final packsToDelete = packs.where((p) => packToDeleteNames.contains(p.name));
			
			final untiedCardsCount = packsToDelete.fold<int>(0, (res, i) => res + i.cardsNumber);

			final nonePack = await _getNonePack(storage, tester);
			final nonePacksNumber = nonePack.cardsNumber;
			
			await screenTester.deleteSelectedItems(assistant, shouldAccept: true);
			await screenTester.deactivateEditorMode(assistant);
			
    		await _assertPackCardNumber(tester, storage, nonePack, 
				nonePacksNumber + untiedCardsCount);
		});

	testWidgets("Doesn't increase the number of cards without a pack when cancelling their pack deletion", 
		(tester) async {
			final storage = await screenTester.pumpScreen(tester) as PackStorageMock;

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
			final packWithoutCards = PackStorageMock.generatePack(Randomiser.nextInt(100) + 99);
			await screenTester.pumpScreen(tester, (st) async {
				final storage = st as PackStorageMock;

				await tester.runAsync(() => storage.upsert([packWithoutCards]));
			});
			
			final assistant = new WidgetAssistant(tester);
			await screenTester.activateEditorMode(assistant);
			
			await screenTester.selectItemsInEditor(assistant, [packWithoutCards.name]);

			await screenTester.deleteSelectedItems(assistant, shouldNotWarn: true);
		});

	testWidgets("Changes the export/import action when selecting/unselecting packs respectively", 
		(tester) async {
			await screenTester.pumpScreen(tester);
	
			final assistant = new WidgetAssistant(tester);
			await screenTester.activateEditorMode(assistant);
	
			_findImportExportAction(isExport: false, shouldFind: true);
			_findImportExportAction(isExport: true, shouldFind: false);

			await screenTester.selectSomeItemsInEditor(assistant);
	
			_findImportExportAction(isExport: true, shouldFind: true);
			_findImportExportAction(isExport: false, shouldFind: false);
		});

	testWidgets("Exports selected packs into a JSON-file and shows its path thereafter", (tester) async {
		final storage = await screenTester.pumpScreen(tester) as PackStorageMock;

		final assistant = new WidgetAssistant(tester);
		await screenTester.activateEditorMode(assistant);
		final selectedPackDic = await screenTester.selectSomeItemsInEditor(assistant);

		final packsToExport = (await _fetchPacks(storage, tester))
			.where((p) => selectedPackDic.containsValue(p.name)).toList();

		await FakePathProviderPlatform.testWithinPathProviderContext(() async {
			final exportBtnFinder = _findImportExportAction(isExport: true, shouldFind: true);
			await assistant.tapWidget(exportBtnFinder);

			final dialog = DialogTester.findConfirmationDialog(tester);
			final exportFilePath = (dialog.content as Text).data.split(' ').last;
			
			final exporterTester = new ExporterTester(exportFilePath);
			exporterTester.assertExportFileName('packs');
			
			await tester.runAsync(() => exporterTester.assertExportedPacks(storage, packsToExport));
		});
	});

	testWidgets("Warns about a non-existent file when trying to import packs from it", (tester) async {
		await screenTester.pumpScreen(tester);
		final assistant = new WidgetAssistant(tester);

		await screenTester.activateEditorMode(assistant);
		
		final importFilePath = Randomiser.nextString() + '.json';
		await _activateImport(assistant, importFilePath);

		final importInfo = _findConfirmationDialogText(tester);
		final locale = Localizator.defaultLocalization;
		expect(importInfo, locale.packListScreenImportDialogWrongFormatContent(importFilePath));
	});

	testWidgets("Warns about a file of an incorrect format when trying to import packs from it", 
		(tester) async {
			await screenTester.pumpScreen(tester);

			final assistant = new WidgetAssistant(tester);
			await screenTester.activateEditorMode(assistant);
			
			await FakePathProviderPlatform.testWithinPathProviderContext(() async {
				final importFilePath = await ExporterTester.writeToJsonFile([
					Randomiser.nextInt(), Randomiser.nextString(), Randomiser.nextInt()]);
				await _activateImport(assistant, importFilePath);

				final importInfo = _findConfirmationDialogText(tester);
				final locale = Localizator.defaultLocalization;
				expect(importInfo, locale.packListScreenImportDialogWrongFormatContent(importFilePath));
			});
		});

	testWidgets("Imports packs from a JSON-file and shows the newly added packs with and the result of the operation", 
		(tester) async {
			final storage = await screenTester.pumpScreen(tester) as PackStorageMock;
			final assistant = new WidgetAssistant(tester);

			await _testImportingPacks(assistant, storage, screenTester);

			await screenTester.deactivateEditorMode(assistant);
		});
	
	testWidgets("Imports packs, adds a new search index and goes to the default search index", (tester) async {
		final storage = new PackStorageMock();
	    final inScreenTester = new ListScreenTester('Pack', 
			([_]) => _buildPackListScreen(storage: storage));

		final indexes = await inScreenTester.testSwitchingToSearchMode(tester, 
			newEntityGetter: PackStorageMock.generatePack, 
			shouldKeepInSearchMode: true
		);

		final activeIndex = indexes.first;
		final assistant = new WidgetAssistant(tester);
		await inScreenTester.chooseFilterIndex(assistant, activeIndex);

		final exportedPacks = await _testImportingPacks(assistant, storage, inScreenTester);
		await assistant.pumpAndAnimate(500);

		inScreenTester.findSearcherEndButton(shouldFind: true);

		final newIndexes = new Map<String, int>.fromIterable(
			indexes..addAll(exportedPacks.map((p) => p.name[0].toUpperCase())), 
			key: (i) => i, value: (_) => 0).keys.toList();
		inScreenTester.assureFilterIndexes(newIndexes, shouldFind: true);

		inScreenTester.assureFilterIndexActiveness(tester, activeIndex, isActive: false);

		await inScreenTester.deactivateSearcherMode(assistant);

		await inScreenTester.deactivateEditorMode(assistant);
	});
}

PackListScreen _buildPackListScreen({ PackStorageMock storage, int packsNumber }) {
	storage = storage ?? new PackStorageMock(packsNumber: packsNumber ?? 40, 
		textGetter: (text, id) => (id % 2).toString() + text);
	return new PackListScreen(storage, storage.wordStorage);
}
    
Future<PackStorageMock> _pumpScreenWithRouting(WidgetTester tester, { bool cardWasAdded }) async {
    final storage = new PackStorageMock();
    await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
		onGenerateRoute: (settings) {
            final route = Router.getRoute(settings);

            if (route == null)
                return new MaterialPageRoute(
                    settings: settings,
                    builder: (context) => new RootWidgetMock(
						child: new MainScreen(new ContactsParams(
							fbUserId: Randomiser.nextString()
						))
					)
                );
            if (route is CardListRoute)
                return new MaterialPageRoute(
                    settings: settings,
                    builder: (context) => new RootWidgetMock(
                        child: new CardListScreen(storage.wordStorage, pack: route.params.pack, 
                            cardWasAdded: cardWasAdded))
                );
            else if (route is PackRoute)
                return new MaterialPageRoute(
                    settings: settings,
                    builder: (context) => new RootWidgetMock(
                        child: new PackScreen(storage, new DictionaryProviderMock(), 
							packId: route.params.packId, refreshed: route.params.refreshed))
                );

            return new MaterialPageRoute(
                settings: settings,
                builder: (context) => new RootWidgetMock(child: _buildPackListScreen(storage: storage))
            );
        })
	);

    await tester.pump(new Duration(milliseconds: 500));

    final finder = find.byIcon(Icons.library_books);
    await new WidgetAssistant(tester).tapWidget(finder);

    return storage;
}

Future<StoredPack> _getFirstPackWithEnoughCards(PackStorageMock storage, WidgetTester tester) async =>
	(await _fetchPacks(storage, tester))
		.firstWhere((p) => p.cardsNumber > 0 && p.cardsNumber < 8 && p.name != StoredPack.noneName);

Future<List<StoredPack>> _fetchPacks(PackStorageMock storage, WidgetTester tester) =>    
	tester.runAsync<List<StoredPack>>(() => storage.fetch());

Future<void> _testShowingCardsWithoutChanging(WidgetTester tester, 
    PackStorageMock storage, StoredPack pack) async {
    final expectedNumberOfCards = pack.cardsNumber;
        
    final assistant = new WidgetAssistant(tester);

    final packName = pack.name;
    await _goToCardList(assistant, packName);

    expect(find.byType(Dismissible), findsNWidgets(expectedNumberOfCards));

    await _goBackToPackList(assistant, packName);

    await _assertPackCardNumber(tester, storage, pack, expectedNumberOfCards);
}

Future<void> _testDecreasingNumberOfCards(WidgetTester tester, 
    PackStorageMock storage, StoredPack pack) async {
    final expectedNumberOfCards = pack.cardsNumber - 1;
    
    final assistant = new WidgetAssistant(tester);
    await _goToCardList(assistant, pack.name);

	await assistant.swipeWidgetLeft(find.byType(Dismissible).first);
    
    await _goBackToPackList(assistant, pack.name);

    await _assertPackCardNumber(tester, storage, pack, expectedNumberOfCards);
}

Future<void> _testIncreasingNumberOfCards(WidgetTester tester, 
    PackStorageMock storage, StoredPack pack) async {
    final expectedNumberOfCards = pack.cardsNumber + 1;

    final assistant = new WidgetAssistant(tester);
    await _goToCardList(assistant, pack.name);

    await tester.runAsync(() async {
        final randomWord = WordStorageMock.generateWord(packId: pack.id, hasNoPack: pack.isNone);
        await storage.wordStorage.upsert([randomWord]);
    });

    await _goBackToPackList(assistant, pack.name);

    await _assertPackCardNumber(tester, storage, pack, expectedNumberOfCards);
}

Future<void> _goToCardList(WidgetAssistant assistant, String packName) async {
    final tileWithCardsFinder = _findPackTileByName(packName);
    expect(tileWithCardsFinder, findsOneWidget);
    await assistant.tapWidget(tileWithCardsFinder);

    if (packName == StoredPack.noneName) 
        return;

    final cardListBtnFinder = find.byIcon(Icons.filter_1);
    expect(cardListBtnFinder, findsOneWidget);
    await assistant.tapWidget(cardListBtnFinder);
}

Finder _findPackTileByName(String name) {
    final nonePackTileFinder = find.ancestor(of: find.text(name), 
        matching: find.byType(ListTile), matchRoot: true);
    expect(nonePackTileFinder, findsOneWidget);

    return nonePackTileFinder;
}

Future<void> _goBackToPackList(WidgetAssistant assistant, String packName) async {
    await _goBack(assistant);

    if (packName == StoredPack.noneName) 
        return;

    await _goBack(assistant);
}

Future<void> _goBack(WidgetAssistant assistant) async {
    final backBtnFinders = find.byType(BackButton);
    assistant.tester.widget<BackButton>(backBtnFinders.first).onPressed.call();

    await assistant.pumpAndAnimate();
}

Future<void> _assertPackCardNumber(WidgetTester tester, PackStorageMock storage, 
    StoredPack pack, int expectedNumber) async {
    final tileWithCardsFinder = find.ancestor(of: find.text(pack.name), 
        matching: find.byType(ListTile));
    expect(tileWithCardsFinder, findsOneWidget);
    
    expect(find.descendant(
		of: tileWithCardsFinder, 
        matching: find.text(
			Localizator.defaultLocalization.cardNumberIndicatorContent(expectedNumber)
		)
	), findsOneWidget);

    await tester.runAsync(() async {
		final actualPackWithCards = (pack.id == null ? (await storage.fetch()).first: 
			await storage.find(pack.id));
        expect(actualPackWithCards?.cardsNumber, expectedNumber);
    });
}

Future<StoredPack> _getNonePack(PackStorageMock storage, WidgetTester tester) async => 
	(await _fetchPacks(storage, tester)).firstWhere((p) => p.name == StoredPack.noneName);

Future<List<StoredPack>> _testImportingPacks(
	WidgetAssistant assistant, PackStorageMock storage, ListScreenTester screenTester
) async {
	final tester = assistant.tester;
	final packsToExport = ExporterTester.getPacksForExport(storage);
	final existentPackIds = (await tester.runAsync(() => storage.fetch())).map((p) => p.id).toList();

	await FakePathProviderPlatform.testWithinPathProviderContext(() async {
		final importFilePath = await tester.runAsync(() =>
			new PackExporter(storage.wordStorage).export(packsToExport, Randomiser.nextString()));

		await screenTester.activateEditorMode(assistant);
		
		await _activateImport(assistant, importFilePath);

		final importInfo = _findConfirmationDialogText(tester);
		expect(importInfo.contains(packsToExport.length.toString()), true);
		expect(importInfo.contains(importFilePath), true);

		final storedCards = await tester.runAsync(() => storage.wordStorage.fetchFiltered(
			parentIds: packsToExport.map((p) => p.id).toList()));
		expect(importInfo.contains(storedCards.length.toString()), true, 
			reason: 'A message "$importInfo" does not contain the number of imported packs=${storedCards.length}');

		await assistant.tapWidget(DialogTester.findConfirmationDialogBtn());

		for (final importedPack in packsToExport..sort((a, b) => a.name.compareTo(b.name))) {
			await assistant.scrollUntilVisible(find.text(importedPack.name), CheckboxListTile);

			final isDuplicatedPack = existentPackIds.contains(importedPack.id);
			final matcher = findsNWidgets(isDuplicatedPack ? 2: 1);
			final packNameFinders =	find.text(importedPack.name, skipOffstage: false);
			expect(packNameFinders, matcher);
			
			final packTileFinders = find.ancestor(of: packNameFinders, 
				matching: find.byType(CheckboxListTile, skipOffstage: false));
			expect(packTileFinders, matcher);
			
			final cardsNumberIndicators = tester.widgetList<CardNumberIndicator>(find.descendant(
				of: packTileFinders, 
				matching: find.byType(CardNumberIndicator, skipOffstage: false)
			));
			cardsNumberIndicators.forEach((i) => i.number == importedPack.cardsNumber);

			final langIndicators = tester.widgetList<TranslationIndicator>(
				find.descendant(of: packTileFinders, 
				matching: find.byType(TranslationIndicator, skipOffstage: false)
			));
			langIndicators.forEach((i) {
				expect(i.from, importedPack.from);
				expect(i.to, importedPack.to);
			});
		}
	});

	return packsToExport;
}

Future<void> _activateImport(WidgetAssistant assistant, String importFilePath) async {			
	final importBtnFinder = _findImportExportAction(isExport: false, shouldFind: true);
	await assistant.tapWidget(importBtnFinder);

	final filePathTxtFinder = AssuredFinder.findOne(type: TextField, shouldFind: true);
	await assistant.tester.enterText(filePathTxtFinder, importFilePath);

	final importConfirmationBtnFinder = find.widgetWithText(
		ElevatedButton, Localizator.defaultLocalization.importDialogImportBtnLabel);
	await assistant.tapWidget(importConfirmationBtnFinder);
}

Finder _findImportExportAction({ bool isExport, bool shouldFind }) {
	final locale = Localizator.defaultLocalization;
	return AssuredFinder.findOne(icon: Icons.import_export, 
		label: isExport ? locale.packListScreenBottomNavBarExportActionLabel:
			locale.packListScreenBottomNavBarImportActionLabel, 
		shouldFind:  shouldFind);
}

String _findConfirmationDialogText(WidgetTester tester) {
	final dialog = DialogTester.findConfirmationDialog(tester);
	return (dialog.content as Text).data;
}
