import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/card_list_screen.dart';
import 'package:language_cards/src/screens/list_screen.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/word_storage_mock.dart';
import '../../testers/dialog_tester.dart';
import '../../testers/list_screen_tester.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/widget_assistant.dart';

void main() {
    final screenTester = _buildScreenTester();
    screenTester.testEditorMode();
    screenTester.testSearchMode((id) => WordStorageMock.generateWord(id: id));
	
    screenTester.testDismissingItems();

	testWidgets('Switches to the search mode for cards grouped by a pack', (tester) async {
		final packStorage = new PackStorageMock(cardsNumber: 70);
		final pack = (await tester.runAsync(() => packStorage.fetch()))
			.firstWhere((p) => !p.isNone && p.cardsNumber > 0);
		final wordStorage = packStorage.wordStorage;

		final groupedScreenTester = _buildScreenTester(wordStorage, pack);
		final childCards = await tester.runAsync(() => wordStorage.fetchFiltered(parentIds: [pack.id]));
		
		int index = 0;
		await tester.runAsync(() => wordStorage.upsert(
			childCards.map((e) => new StoredWord((index++ % 2).toString() + e.text, 
			id: e.id, packId: e.packId, partOfSpeech: e.partOfSpeech, studyProgress: e.studyProgress, 
			transcription: e.transcription, translation: e.translation)).toList()));

		await groupedScreenTester.testSwitchingToSearchMode(tester, 
			newEntityGetter: (index) => WordStorageMock.generateWord(id: 100 + index, packId: pack.id),
			itemsLengthGetter: () => Future.value(childCards.length),
			indexGroupsGetter: (_) async {
				final indexGroups = await tester.runAsync(() => 
					wordStorage.groupByTextIndexAndParent([pack.id]));
				expect(indexGroups.length, 2);
				return indexGroups;
			});
	});

    testWidgets('Renders study progress for each card', (tester) async {
        final wordStorage = await screenTester.pumpScreen(tester) as WordStorageMock;
        final words = await _fetchWords(tester, wordStorage);

        final listItemFinders = find.descendant(
            of: screenTester.tryFindingListItems(shouldFind: true), 
            matching: find.byType(ListTile));
        final itemsLength = listItemFinders.evaluate().length;
        for (int i = 0; i < itemsLength; ++i) {
            final word = words[i];
            expect(find.descendant(of: listItemFinders.at(i), 
                matching: find.text('${word.studyProgress}%')), findsOneWidget);
        }
    });

    testWidgets("Cancels resetting study progress for selected cards when it wasn't confirmed", 
        (tester) async {
            final wordStorage = await screenTester.pumpScreen(tester) as WordStorageMock;
            final wordWithProgressIndex = 
                await _getIndexOfFirstWordWithProgress(tester, wordStorage);

            final assistant = new WidgetAssistant(tester);
            await screenTester.activateEditorMode(assistant);
            
            final selectedItems = (await screenTester.selectSomeItemsInEditor(assistant, 
                wordWithProgressIndex)).values;
            final selectedWords = (await _fetchWords(tester, wordStorage))
                .where((w) => selectedItems.contains(w.text));
            final selectedWordsWithProgress = <String, int> {
				for (var w in selectedWords) w.text: w.studyProgress 
			};
            await _operateResettingProgressDialog(assistant, shouldConfirm: false);

            await screenTester.deactivateEditorMode(assistant);
            final assuredWords = await _assureStudyProgressForWords(tester, screenTester, 
                wordStorage);
            expect(selectedWordsWithProgress.entries.every((entry) => 
                assuredWords.any((word) => word.text == entry.key && 
                    word.studyProgress == entry.value)), true);
        });

    testWidgets('Resets study progress for selected cards', (tester) async {
        final wordStorage = await screenTester.pumpScreen(tester) as WordStorageMock;
		final wordWithProgressIndex = 
            await _getIndexOfFirstWordWithProgress(tester, wordStorage);

        final assistant = new WidgetAssistant(tester);
        await screenTester.activateEditorMode(assistant);

        final selectedItems = await screenTester.selectSomeItemsInEditor(assistant, 
            wordWithProgressIndex);
        
        await _operateResettingProgressDialog(assistant, shouldConfirm: true);

        await screenTester.deactivateEditorMode(assistant);
        final assuredWords = await _assureStudyProgressForWords(tester, screenTester, 
            wordStorage);
        expect(selectedItems.values.every((text) => 
            assuredWords.any((word) => word.text == text && 
                word.studyProgress == WordStudyStage.unknown)), true);
    });

    testWidgets('Shows no dialog to reset study progress for cards without progress', 
        (tester) async {
            final storage = new WordStorageMock();
            final inScreenTester = _buildScreenTester(storage);

            final words = await _fetchWords(tester, storage);
            words.forEach((w) => w.resetStudyProgress());
            await storage.upsert(words);

            await inScreenTester.pumpScreen(tester);

            final assistant = new WidgetAssistant(tester);
            await inScreenTester.activateEditorMode(assistant);

            await inScreenTester.selectSomeItemsInEditor(assistant);
            
            await _operateResettingProgressDialog(assistant, shouldConfirm: true, 
                assureNoDialog: true);
        });

	testWidgets('Selects all cards on a page and scrolls down until others get available to select them too', 
        (tester) async {
			final packsStorage = new PackStorageMock(cardsNumber: (ListScreen.itemsPerPage * 1.5).toInt());
			await _testSelectingOnPage(tester, packsStorage.wordStorage);
        });

	testWidgets('Deletes all cards on a page and then deletes some of the left ones available on other pages', 
        (tester) async {
			final itemsOverall = (ListScreen.itemsPerPage * 1.5).toInt();
			final packsStorage = new PackStorageMock(cardsNumber: itemsOverall);
			final storage = packsStorage.wordStorage;
			
			final inScreenTester = _buildScreenTester(storage);
			await inScreenTester.pumpScreen(tester);

			final assistant = new WidgetAssistant(tester);
			await inScreenTester.activateEditorMode(assistant);
			
			await inScreenTester.selectAll(assistant);
			await inScreenTester.deleteSelectedItems(assistant);	
			inScreenTester.tryFindingListCheckTiles(shouldFind: true);

			final expectedCardsNumber = itemsOverall - ListScreen.itemsPerPage;
			final locale = Localizator.defaultLocalization;
			expect(inScreenTester.getSelectorBtnLabel(tester), 
				locale.constsSelectAll(expectedCardsNumber.toString()));
        
			final deletedItems = await inScreenTester.selectSomeItemsInEditor(assistant);
			await inScreenTester.deleteSelectedItems(assistant);	
			inScreenTester.tryFindingListCheckTiles(shouldFind: true);

			final finalCardsNumber = expectedCardsNumber - deletedItems.length;
			expect(inScreenTester.getSelectorBtnLabel(tester), 
				locale.constsSelectAll(finalCardsNumber.toString()));
        });

	testWidgets('Selects all grouped cards on a page and scrolls down until others get available to select them too', 
        (tester) async {
			final packsStorage = new PackStorageMock(
				cardsNumber: (ListScreen.itemsPerPage * 2.1).toInt(),
				packsNumber: 2
			);
			await _testSelectingOnPage(tester, packsStorage.wordStorage, packsStorage.getRandom());
        });

	testWidgets('Scrolls down till the end of a short list of cards without changing the number of cards available for selection', 
        (tester) async {
			const int expectedCardsNumber = 15;
			final packsStorage = new PackStorageMock(cardsNumber: expectedCardsNumber);
			final inScreenTester = _buildScreenTester(packsStorage.wordStorage);
			await inScreenTester.pumpScreen(tester);

			final assistant = new WidgetAssistant(tester);
			await assistant.scrollDownListView(find.byType(ListTile), iterations: 5);
			await inScreenTester.activateEditorMode(assistant);

			expect(inScreenTester.getSelectorBtnLabel(tester), 
				Localizator.defaultLocalization.constsSelectAll(expectedCardsNumber.toString()));
        });
}

ListScreenTester<StoredWord> _buildScreenTester([WordStorageMock storage, StoredPack pack]) {
	return new ListScreenTester('Card', ([cardsNumber]) =>
		new CardListScreen(storage ?? new WordStorageMock(
			cardsNumber: cardsNumber ?? 40, 
			textGetter: (text, id) => (id % 2).toString() + text
		), pack: pack));
}
    
Future<List<StoredWord>> _assureStudyProgressForWords(WidgetTester tester, 
    ListScreenTester screenTester, WordStorageMock storage) async {
    final words = await _fetchWords(tester, storage);

    final assuredWords = <StoredWord>[];
    final listItemFinders = find.descendant(
        of: screenTester.tryFindingListItems(shouldFind: true), 
        matching: find.byType(ListTile));
    final itemsLength = listItemFinders.evaluate().length;
    for (int i = 0; i < itemsLength; ++i) {
        final word = words[i];
        assuredWords.add(word);

        expect(find.descendant(of: listItemFinders.at(i), 
            matching: find.text('${word.studyProgress}%')), findsOneWidget);
    }

    return assuredWords;
}

Future<List<StoredWord>> _fetchWords(WidgetTester tester, WordStorageMock storage) => 
	tester.runAsync(() => storage.fetchFiltered());

Finder _findRestoreBtn({ bool shouldFind }) => 
    AssuredFinder.findOne(icon: Icons.restore, shouldFind: shouldFind);

Finder _findBtnByLabel(String label, { bool shouldFind = true }) {
	final finder = DialogTester.findConfirmationDialogBtn(label);
	expect(finder, AssuredFinder.matchOne(shouldFind : shouldFind));

	return finder;
}

Future<void> _operateResettingProgressDialog(WidgetAssistant assistant, 
    { bool shouldConfirm, bool assureNoDialog = false }) async {
        final restoreBtnFinder = _findRestoreBtn(shouldFind: true);
        await assistant.tapWidget(restoreBtnFinder);

        final actionBtnFinder = _findBtnByLabel(
			shouldConfirm ? 
				'Yes': Localizator.defaultLocalization.cancellableDialogCancellationButtonLabel,
            shouldFind: !assureNoDialog
		);
        if (!assureNoDialog)
            await assistant.tapWidget(actionBtnFinder);
    }

Future<int> _getIndexOfFirstWordWithProgress(WidgetTester tester, 
    WordStorageMock storage) async {
        final words = (await _fetchWords(tester, storage)).toList();
        int wordWithProgressIndex = words.indexWhere(
            (w) => w.studyProgress > WordStudyStage.unknown);
            
        if (wordWithProgressIndex == -1) {
            wordWithProgressIndex = 0;
            await storage.updateWordProgress(words[wordWithProgressIndex].id, 
                WordStudyStage.learned);
        }
            
        return wordWithProgressIndex;
    }

Future<void> _testSelectingOnPage(
	WidgetTester tester, WordStorageMock storage, [StoredPack pack]
) async {
	final inScreenTester = _buildScreenTester(storage, pack);
	await inScreenTester.pumpScreen(tester);

	final assistant = new WidgetAssistant(tester);
	await inScreenTester.activateEditorMode(assistant);
	await inScreenTester.selectAll(assistant);

	final expectedCardNumberStr = 
		(await tester.runAsync(() => storage.count(parentId: pack?.id))).toString();
	final locale = Localizator.defaultLocalization;
	expect(inScreenTester.getSelectorBtnLabel(tester),
		locale.constsUnselectSome(ListScreen.itemsPerPage.toString(), expectedCardNumberStr));

	await assistant.scrollDownListView(find.byType(CheckboxListTile), iterations: 25);
	expect(inScreenTester.getSelectorBtnLabel(tester), 
		locale.constsSelectAll(expectedCardNumberStr));
	inScreenTester.assureSelectionForAllTilesInEditor(tester, onlyForSomeItems: true);

	await inScreenTester.selectAll(assistant);
	inScreenTester.assureSelectionForAllTilesInEditor(tester, selected: true);
}
