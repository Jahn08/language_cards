import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/card_list_screen.dart';
import '../testers/list_screen_tester.dart';
import '../utilities/assured_finder.dart';
import '../utilities/mock_word_storage.dart';
import '../utilities/widget_assistant.dart';

void main() {
    final wordStorage = new MockWordStorage();
    final screenTester = new ListScreenTester('Card', 
        () => new CardListScreen(wordStorage));
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
            await screenTester.pumpScreen(tester);

            final assistant = new WidgetAssistant(tester);
            await screenTester.activateEditorMode(assistant);
            
            final selectedItems = (await screenTester.selectSomeItemsInEditor(assistant))
                .values;
            final selectedWords = (await _fetchWords(tester, wordStorage))
                    .where((w) => selectedItems.contains(w.text)).toList();
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
        await screenTester.pumpScreen(tester);

        final assistant = new WidgetAssistant(tester);
        await screenTester.activateEditorMode(assistant);
        final selectedItems = await screenTester.selectSomeItemsInEditor(assistant);
        
        await _operateResettingProgressDialog(assistant, shouldConfirm: true);

        await screenTester.deactivateEditorMode(assistant);
        final assuredWords = await _assureStudyProgressForWords(tester, screenTester, 
            wordStorage);
        expect(selectedItems.values.every((text) => 
            assuredWords.any((word) => word.text == text && 
                word.studyProgress == WordStudyStage.unknown)), true);
    });
}

Future<List<StoredWord>> _assureStudyProgressForWords(WidgetTester tester, 
    ListScreenTester screenTester, MockWordStorage storage) async {
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

Future<List<StoredWord>> _fetchWords(WidgetTester tester, MockWordStorage storage) async {
    List<StoredWord> words;
    await tester.runAsync(() async => words = (await storage.fetch()));

    return words;
}

Finder _findRestoreBtn({ bool shouldFind }) => 
    AssuredFinder.findOne(icon: Icons.restore, shouldFind: shouldFind);

Finder _findBtnByLabel(String label) => 
    AssuredFinder.findOne(type: FlatButton, label: label, shouldFind: true);

Future<void> _operateResettingProgressDialog(WidgetAssistant assistant, { bool shouldConfirm }) 
    async {
        final restoreBtnFinder = _findRestoreBtn(shouldFind: true);
        await assistant.tapWidget(restoreBtnFinder);
        await assistant.tapWidget(_findBtnByLabel(shouldConfirm ? 'Yes': 'No'));
    }
