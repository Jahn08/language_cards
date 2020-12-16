import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/card_list_screen.dart';
import '../mocks/word_storage_mock.dart';
import '../testers/list_screen_tester.dart';
import '../utilities/assured_finder.dart';
import '../utilities/widget_assistant.dart';

void main() {
    final wordStorage = new WordStorageMock();
    final screenTester = _buildScreenTester(wordStorage);
    screenTester.testEditorMode();

    testWidgets('Renders study progress for each card', (tester) async {
        await screenTester.pumpScreen(tester);
        
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
            final wordWithProgressIndex = 
                await _getIndexOfFirstWordWithProgress(tester, wordStorage);
            
            await screenTester.pumpScreen(tester);

            final assistant = new WidgetAssistant(tester);
            await screenTester.activateEditorMode(assistant);
            
            final selectedItems = (await screenTester.selectSomeItemsInEditor(assistant, 
                wordWithProgressIndex)).values;
            final selectedWords = (await _fetchWords(tester, wordStorage))
                .where((w) => selectedItems.contains(w.text));
            final selectedWordsWithProgress = new Map<String, int>.fromIterable(
                selectedWords, 
                value: (w) => w.studyProgress,
                key: (w) => w.text);

            await _operateResettingProgressDialog(assistant, shouldConfirm: false);

            await screenTester.deactivateEditorMode(assistant);
            final assuredWords = await _assureStudyProgressForWords(tester, screenTester, 
                wordStorage);
            expect(selectedWordsWithProgress.entries.every((entry) => 
                assuredWords.any((word) => word.text == entry.key && 
                    word.studyProgress == entry.value)), true);
        });

    testWidgets('Resets study progress for selected cards', (tester) async {
        final wordWithProgressIndex = 
            await _getIndexOfFirstWordWithProgress(tester, wordStorage);

        await screenTester.pumpScreen(tester);

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
            await storage.update(words);

            await inScreenTester.pumpScreen(tester);

            final assistant = new WidgetAssistant(tester);
            await inScreenTester.activateEditorMode(assistant);

            await inScreenTester.selectSomeItemsInEditor(assistant);
            
            await _operateResettingProgressDialog(assistant, shouldConfirm: true, 
                assureNoDialog: true);
        });
}

ListScreenTester _buildScreenTester(WordStorageMock storage) => 
    new ListScreenTester('Card', () => new CardListScreen(storage));

Future<List<StoredWord>> _assureStudyProgressForWords(WidgetTester tester, 
    ListScreenTester screenTester, WordStorageMock storage) async {
    List<StoredWord> words;
    await tester.runAsync(() async => words = (await storage.fetch()));

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

Future<List<StoredWord>> _fetchWords(WidgetTester tester, WordStorageMock storage) async {
    List<StoredWord> words;
    await tester.runAsync(() async => words = (await storage.fetch()));

    return words;
}

Finder _findRestoreBtn({ bool shouldFind }) => 
    AssuredFinder.findOne(icon: Icons.restore, shouldFind: shouldFind);

Finder _findBtnByLabel(String label, { bool shouldFind = true }) => 
    AssuredFinder.findOne(type: FlatButton, label: label, shouldFind: shouldFind);

Future<void> _operateResettingProgressDialog(WidgetAssistant assistant, 
    { bool shouldConfirm, bool assureNoDialog = false }) async {
        final restoreBtnFinder = _findRestoreBtn(shouldFind: true);
        await assistant.tapWidget(restoreBtnFinder);

        final actionBtnFinder = _findBtnByLabel(shouldConfirm ? 'Yes': 'No', 
            shouldFind: !assureNoDialog);
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
