import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/screens/new_card_screen.dart';
import '../utilities/test_root_widget.dart';
import '../utilities/mock_word_storage.dart';

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

            final expectedNewWordText = wordToShow.text.substring(1);
            await tester.enterText(find.widgetWithText(TextField, wordToShow.text), 
                expectedNewWordText);
            await tester.pumpAndSettle();

            final translationFieldFinder = find.widgetWithText(TextField, wordToShow.translation);
            expect(translationFieldFinder, findsOneWidget);
            await tester.tap(translationFieldFinder);
            await tester.pumpAndSettle();

            final wordFieldFinder = find.widgetWithText(TextField, expectedNewWordText);
            expect(wordFieldFinder, findsOneWidget);

            final translationField = tester.widget<TextField>(translationFieldFinder);
            expect(translationField.focusNode.hasFocus, true);
        });
}

Future<StoredWord> _displayWord(WidgetTester tester) async {
    final storage = new MockWordStorage();
    final wordToShow = storage.getRandomWord();
    await tester.pumpWidget(TestRootWidget.buildAsAppHome(
        child: new NewCardScreen('', storage, wordId: wordToShow.id)));
    await tester.pumpAndSettle();

    return wordToShow;
}

Type _typify<T>() => T;
