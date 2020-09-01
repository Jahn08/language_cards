import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/screens/new_card_screen.dart';
import '../utilities/test_root_widget.dart';
import '../utilities/mock_word_storage.dart';
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
            final storage = new MockWordStorage();
            final wordToShow = await _displayWord(tester, storage);

            final assistant = new WidgetAssistant(tester);
            await _showTranscriptionKeyboard(assistant, wordToShow.transcription);

            final expectedChangedTr = await _changeTranscription(assistant, wordToShow.transcription);

            await assistant.pressButtonDirectly(_findSaveButton());

            final changedWord = await storage.find(wordToShow.id);
            expect(changedWord?.transcription, expectedChangedTr);
        });
}

Future<StoredWord> _displayWord(WidgetTester tester, [MockWordStorage storage]) async {
    storage = storage ?? new MockWordStorage();
    final wordToShow = storage.getRandomWord();

    await tester.pumpWidget(TestRootWidget.buildAsAppHome(
        child: new NewCardScreen('', storage, wordId: wordToShow.id)));
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
    final storage = new MockWordStorage();
    final wordToShow = await _displayWord(tester, storage);

    final expectedChangedText = await _enterChangedText(tester, valueToChangeGetter(wordToShow));

    await new WidgetAssistant(tester).tapWidget(_findSaveButton());
    await tester.pumpAndSettle();

    final changedWord = await storage.find(wordToShow.id);
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
