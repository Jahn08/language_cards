import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/card_screen.dart';
import '../utilities/mock_pack_storage.dart';
import '../utilities/randomiser.dart';
import '../utilities/test_root_widget.dart';
import '../utilities/widget_assistant.dart';

void main() {

    testWidgets('Builds a screen displaying fields for a word from a storage', 
        (tester) async {
            final wordToShow = await _displayWord(tester);
            
            expect(find.widgetWithText(TextField, wordToShow.text), findsOneWidget);
            expect(find.widgetWithText(TextField, wordToShow.translation), findsOneWidget);
            
            var transcriptionFieldFinder = find.widgetWithText(TextField, wordToShow.transcription);
            expect(transcriptionFieldFinder, findsOneWidget);

            final posField = tester.widget<DropdownButton<String>>(
                find.byType(_typify<DropdownButton<String>>()));
            expect(posField.value, wordToShow.partOfSpeech);
        });

    testWidgets('Displays a card pack for a word from a storage', 
        (tester) async {
            final expectedPack = MockPackStorage.generatePack(
                Randomiser.nextInt(MockPackStorage.packNumber));
            await _displayWord(tester, pack: expectedPack);

            await _testDisplayingPackName(tester, expectedPack);
        });

    testWidgets('Displays no button showing study progress for a card with the zero progress', 
        (tester) async {
            final storage = new MockPackStorage();
            final wordWithoutProgress = storage.wordStorage.getRandom();
            if (wordWithoutProgress.studyProgress != WordStudyStage.unknown)
                wordWithoutProgress.resetStudyProgress();

            await _displayWord(tester, storage: storage, wordToShow: wordWithoutProgress);

            _findStudyProgressButton(shouldFind: false);
        });

    testWidgets('Displays a button showing study progress for a card and resetting it', 
        (tester) async {
            final storage = new MockPackStorage();
            StoredWord wordWithProgress;
            await tester.runAsync(() async => wordWithProgress = (await storage.wordStorage.fetch())
                .firstWhere((w) => w.studyProgress != WordStudyStage.unknown));
            await _displayWord(tester, storage: storage, wordToShow: wordWithProgress);

            final progressBtnFinder = _findStudyProgressButton();
            final progressLabelFinder = find.descendant(of: progressBtnFinder, 
                matching: find.byType(Text));
            expect(progressLabelFinder, findsOneWidget);
            expect(tester.widget<Text>(progressLabelFinder)
                .data.contains('${wordWithProgress.studyProgress}%'), true);

            final assistant = new WidgetAssistant(tester);
            await assistant.tapWidget(progressBtnFinder);
            _findStudyProgressButton(shouldFind: false);

            await assistant.pressButtonDirectly(_findSaveButton());

            final changedWord = await storage.wordStorage.find(wordWithProgress.id);
            expect(changedWord.studyProgress, WordStudyStage.unknown);
        });

    testWidgets('Displays no card pack name for a word from a storage without a pack', 
        (tester) async {
            await _displayWord(tester);
            
            await _testDisplayingPackName(tester);
        });

    testWidgets('Displays a currently chosen pack as highlighted in the dialog and changes it', 
        (tester) async {
            final storage = new MockPackStorage();
            final expectedPack = storage.getRandom();
            await _displayWord(tester, storage: storage, pack: expectedPack);
            
            final assistant = new WidgetAssistant(tester);
            final packBtnFinder = _findPackButton();
            await assistant.tapWidget(packBtnFinder);

            final packTileFinder = _findListTileByTitle(expectedPack.name);
            _assureTileIsTicked(packTileFinder);

            StoredPack anotherExpectedPack;
            await tester.runAsync(() async => 
                anotherExpectedPack = await _fetchAnotherPack(storage, expectedPack.id));
            final anotherPackTileFinder = _findListTileByTitle(anotherExpectedPack.name);
            await assistant.tapWidget(anotherPackTileFinder);

            await assistant.tapWidget(packBtnFinder);

            _assureTileIsTicked(anotherPackTileFinder);
        });

    testWidgets('Switches focus to the translation field after changes in the word text field', 
        (tester) async {
            final wordToShow = await _displayWord(tester);
            await _testRefocusingChangedValues(tester, wordToShow.text, wordToShow.translation);
        });

    testWidgets('Switches focus to the word text after changes in the translation field', 
        (tester) async {
            final wordToShow = await _displayWord(tester);
            await _testRefocusingChangedValues(tester, wordToShow.translation, wordToShow.text);
        });

    testWidgets('Switches focus to the transcription field after changes in another text field', 
        (tester) async {
            final wordToShow = await _displayWord(tester);
            await _testRefocusingChangedValues(tester, wordToShow.text, wordToShow.transcription);
        });

    testWidgets('Switches focus to another text field after changes in the transcription field', 
        (tester) async {
            final wordToShow = await _displayWord(tester);

            final assistant = new WidgetAssistant(tester);
            await _showTranscriptionKeyboard(assistant, wordToShow.transcription);

            final expectedChangedTr = await _changeTranscription(assistant, wordToShow.transcription);

            final refocusedFieldFinder = find.widgetWithText(TextField, wordToShow.text);
            await new WidgetAssistant(tester).tapWidget(refocusedFieldFinder);

            expect(find.widgetWithText(TextField, expectedChangedTr), findsOneWidget);

            final refocusedField = tester.widget<TextField>(refocusedFieldFinder);
            expect(refocusedField.focusNode.hasFocus, true);
        });

    testWidgets('Saves all changes to a word whereas the word text field is still focused', 
        (tester) async {
            await _testSavingChangedValue(tester, (word) => word.text);
        });
    
    testWidgets('Saves all changes to a word whereas the word translation field is still focused', 
        (tester) async {
            await _testSavingChangedValue(tester, (word) => word.translation);
        });
    
    testWidgets('Saves all changes to a word whereas the word transcription field is still focused', 
        (tester) async {
            final storage = new MockPackStorage();
            final wordToShow = await _displayWord(tester, storage: storage);

            final assistant = new WidgetAssistant(tester);
            await _showTranscriptionKeyboard(assistant, wordToShow.transcription);

            final expectedChangedTr = await _changeTranscription(assistant, wordToShow.transcription);

            await assistant.pressButtonDirectly(_findSaveButton());

            final changedWord = await storage.wordStorage.find(wordToShow.id);
            expect(changedWord?.transcription, expectedChangedTr);
        });
    
    testWidgets('Saves a new pack for a card', 
        (tester) async {
            final storage = new MockPackStorage();
            await _testChangingPack(storage, tester, 
                (word) async => await _fetchAnotherPack(storage, word.packId));
        });
    
    testWidgets('Saves the none pack for a card', 
        (tester) async {
            await _testChangingPack(new MockPackStorage(), tester, 
                (word) => Future.value(StoredPack.none));
        });
}

Future<StoredWord> _displayWord(WidgetTester tester, 
    { MockPackStorage storage, StoredPack pack, StoredWord wordToShow }) async {
    storage = storage ?? new MockPackStorage();
    final wordStorage = storage.wordStorage;
    wordToShow = wordToShow ?? wordStorage.getRandom();

    await tester.pumpWidget(TestRootWidget.buildAsAppHome(
        child: new CardScreen('', wordStorage: wordStorage, packStorage: storage,
        wordId: wordToShow.id, pack: pack)));
    await tester.pumpAndSettle();

    return wordToShow;
}

Future<void> _testRefocusingChangedValues(WidgetTester tester, String fieldValueToChange, 
    String fieldValueToRefocus) async {
    final expectedChangedText = await _enterChangedText(tester, fieldValueToChange);

    final refocusedFieldFinder = find.widgetWithText(TextField, fieldValueToRefocus);
    await new WidgetAssistant(tester).tapWidget(refocusedFieldFinder);

    final initiallyFocusedFieldFinder = find.widgetWithText(TextField, expectedChangedText);
    expect(initiallyFocusedFieldFinder, findsOneWidget);

    final refocusedField = tester.widget<TextField>(refocusedFieldFinder);
    expect(refocusedField.focusNode.hasFocus, true);
}

Future<String> _enterChangedText(WidgetTester tester, String initialText) async {
    final changedText = initialText.substring(1);
    await tester.enterText(find.widgetWithText(TextField, initialText), changedText);
    await tester.pumpAndSettle();

    return changedText;
}

Type _typify<T>() => T;

Future<void> _testSavingChangedValue(WidgetTester tester, 
    String Function(StoredWord) valueToChangeGetter) async {
    final storage = new MockPackStorage();
    final wordToShow = await _displayWord(tester, storage: storage);

    final expectedChangedText = await _enterChangedText(tester, valueToChangeGetter(wordToShow));

    await new WidgetAssistant(tester).tapWidget(_findSaveButton());
    await tester.pumpAndSettle();

    final changedWord = await storage.wordStorage.find(wordToShow.id);
    expect(changedWord == null, false);
    expect(valueToChangeGetter(changedWord), expectedChangedText);
}

Finder _findSaveButton() => find.widgetWithText(RaisedButton, 'Save');

Future<void> _showTranscriptionKeyboard(WidgetAssistant assistant, String transcription) async {
    final transcriptionFinder = find.widgetWithText(TextField, transcription);
    expect(transcriptionFinder, findsOneWidget);

    await assistant.tapWidget(transcriptionFinder);
}

Future<String> _changeTranscription(WidgetAssistant assistant, String curTranscription) async {
    final expectedSymbols = await assistant.enterRandomTranscription();
    return curTranscription + expectedSymbols.join();
}

Finder _findStudyProgressButton({ bool shouldFind = true }) => 
    _findFlatButtonByIcon(Icons.restore, shouldFind: shouldFind);

Finder _findFlatButtonByIcon(IconData icon, { bool shouldFind = true }) {
    final flatBtnFinder = find.ancestor(of: find.byIcon(icon), 
        matching: find.byWidgetPredicate((widget) => widget is FlatButton));
    expect(flatBtnFinder, shouldFind ? findsOneWidget: findsNothing);

    return flatBtnFinder;
}

Future<void> _testDisplayingPackName(WidgetTester tester, [StoredPack expectedPack]) async {
    await _displayWord(tester, pack: expectedPack);
    
    final packBtnFinder = _findPackButton();
    final packLabelFinder = find.descendant(of: packBtnFinder, matching: find.byType(Text));
    expect(packLabelFinder, findsOneWidget);
    
    final packLabel = tester.widget<Text>(packLabelFinder);
    expect(packLabel.data.endsWith(expectedPack?.name ?? StoredPack.noneName), true);
}

Finder _findPackButton() => _findFlatButtonByIcon(Icons.folder_open);

Future<StoredPack> _fetchAnotherPack(MockPackStorage storage, int curPackId) async => 
    (await storage.fetch()).firstWhere((p) => p.cardsNumber > 0 && p.id != curPackId);

Future<void> _testChangingPack(MockPackStorage storage, WidgetTester tester, 
    Future<StoredPack> Function(StoredWord) newPackGetter) async {
    final wordToShow = await _displayWord(tester, storage: storage);

    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(_findPackButton());

    StoredPack expectedPack;
    await tester.runAsync(() async => expectedPack = await newPackGetter(wordToShow));

    final packTileFinder = _findListTileByTitle(expectedPack.name);
    await assistant.tapWidget(packTileFinder);

    await assistant.tapWidget(_findSaveButton());

    final changedWord = await storage.wordStorage.find(wordToShow.id);
    expect(changedWord == null, false);
    expect(changedWord.packId, expectedPack.id);
}

Finder _findListTileByTitle(String title) {
    final tileFinder = find.ancestor(of: find.text(title), 
        matching: find.byType(ListTile));
    expect(tileFinder, findsOneWidget); 

    return tileFinder;
}

void _assureTileIsTicked(Finder tileFinder) => 
    expect(find.descendant(of: tileFinder, matching: find.byIcon(Icons.check)), 
        findsOneWidget);
