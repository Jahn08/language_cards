import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/word.dart';
import 'package:language_cards/src/widgets/word_selector_dialog.dart';
import '../utilities/test_root_widget.dart';
import '../utilities/randomiser.dart';

void main() {

    testWidgets('Returns null for for an empty list of words', (tester) async {
        Word dialogResult;
        await _showDialog(tester, [], (word) => dialogResult = word);
        expect(dialogResult, null);

        expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('Shows the dialog according to items passed as an argument', (tester) async {
        final availableWords = new List<Word>.generate(Randomiser.buildRandomInt(5) + 1, 
            (_) => _buildRandomWord());

        await _showDialog(tester, availableWords);

        final optionFinders = find.byType(SimpleDialogOption);
        final foundOptions = tester.widgetList(optionFinders);
        expect(foundOptions.length, availableWords.length);

        final optionsNumber = availableWords.length;
        for (int i = 0; i < optionsNumber; ++i) {
            final word = availableWords[i];
            expect(find.descendant(of: optionFinders.at(i), matching: find.text(word.partOfSpeech)), 
                findsOneWidget);
            expect(find.descendant(of: optionFinders.at(i), 
                matching: find.text(word.translations.join('; '))), findsOneWidget);
        }
    });

    testWidgets('Returns a chosen word and hides the dialog', (tester) async {
        final availableWords = new List<Word>.generate(Randomiser.buildRandomInt(5) + 1, 
            (_) => _buildRandomWord());

        Word dialogResult;
        await _showDialog(tester, availableWords, (word) => dialogResult = word);

        final optionFinders = find.byType(SimpleDialogOption);
        optionFinders.precache();

        final chosenOptionIndex = Randomiser.buildRandomInt(
            tester.widgetList(optionFinders).length);
        final chosenOptionFinder = optionFinders.at(chosenOptionIndex);
        expect(chosenOptionFinder, findsOneWidget);

        await tester.tap(chosenOptionFinder);
        await tester.pump();

        expect(dialogResult, availableWords[chosenOptionIndex]);
        expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('Returns null after tapping on the cancel button', (tester) async {
        final availableWords = new List<Word>.generate(Randomiser.buildRandomInt(5) + 1, 
            (_) => _buildRandomWord());

        Word dialogResult;
        await _showDialog(tester, availableWords, (word) => dialogResult = word);

        final cancelBtnFinder = find.descendant(of: find.byType(SimpleDialog), 
            matching: find.byType(RaisedButton));
        expect(cancelBtnFinder, findsOneWidget);

        await tester.tap(cancelBtnFinder);
        await tester.pump();

        expect(dialogResult, null);
        expect(find.byType(SimpleDialog), findsNothing);
    });
}

Word _buildRandomWord() => new Word(Randomiser.buildRandomString(), 
    partOfSpeech: Randomiser.getRandomElement(Word.PARTS_OF_SPEECH), 
    transcription: Randomiser.buildRandomString(), 
    translations: Randomiser.buildRandomStringList(3));

Future<void> _showDialog(WidgetTester tester, List<Word> availableWords, 
    [Function(Word) onDialogClose]) async {
    BuildContext context;
    final dialogBtnKey = new Key(Randomiser.buildRandomString());
    await tester.pumpWidget(TestRootWidget.buildAsAppHome(
        onBuilding: (inContext) => context = inContext,
        child: new RaisedButton(
            key: dialogBtnKey,
            onPressed: () async {
                final outcome = await WordSelectorDialog.show(availableWords, context);
                onDialogClose?.call(outcome);
            })
        )
    );

    final foundDialogBtn = find.byKey(dialogBtnKey);
    expect(foundDialogBtn, findsOneWidget);
        
    await tester.tap(foundDialogBtn);
    await tester.pump(new Duration(milliseconds: 200));
}
