import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/word.dart';
import 'package:language_cards/src/dialogs/word_selector_dialog.dart';
import '../testers/dialog_tester.dart';
import '../testers/selector_dialog_tester.dart';
import '../utilities/randomiser.dart';

void main() {

    testWidgets('Returns null for an empty list of words', (tester) async {
        final dialogTester = new SelectorDialogTester<Word>(tester, _buildDialog);

        Word dialogResult;
        await dialogTester.showDialog([], (word) => dialogResult = word);
        expect(dialogResult, null);

		new DialogTester().assureDialog(shouldFind: false);
    });

    testWidgets('Shows the word dialog according to items passed as an argument', (tester) async {
        final availableWords = new List<Word>.generate(Randomiser.nextInt(5) + 1, 
            (_) => _buildRandomWord());

        final dialogTester = new SelectorDialogTester<Word>(tester, _buildDialog);
        await dialogTester.testRenderingOptions(availableWords, (finder, word) {
            expect(find.descendant(of: finder, matching: find.text(word.partOfSpeech)), 
                findsOneWidget);
            expect(find.descendant(of: finder, 
                matching: find.text(word.translations.join('; '))), findsOneWidget);
        }, ListTile);
    });

    testWidgets('Returns a chosen word and hides the dialog', (tester) async {
        final availableWords = new List<Word>.generate(Randomiser.nextInt(5) + 1, 
            (_) => _buildRandomWord());

        final dialogTester = new SelectorDialogTester<Word>(tester, _buildDialog);
        await dialogTester.testTappingItem(availableWords);
    });

    testWidgets('Returns null after tapping the cancel button of the word dialog', 
        (tester) async {
            final dialogTester = new SelectorDialogTester<Word>(tester, _buildDialog);

            final availableWords = new List<Word>.generate(Randomiser.nextInt(5) + 1, 
                (_) => _buildRandomWord());
            await dialogTester.testCancelling(availableWords);
        });
}

Word _buildRandomWord() => new Word(Randomiser.nextString(), 
    partOfSpeech: Randomiser.nextElement(Word.parts_of_speech), 
    transcription: Randomiser.nextString(), 
    translations: Randomiser.nextStringList(maxLength: 3));

WordSelectorDialog _buildDialog(BuildContext context) => new WordSelectorDialog(context);
