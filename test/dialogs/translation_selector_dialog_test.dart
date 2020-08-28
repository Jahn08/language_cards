import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/dialogs/translation_selector_dialog.dart';
import '../utilities/randomiser.dart';
import '../utilities/selector_dialog_revealer.dart';

void main() {

    testWidgets('Returns null for for an empty list of translations', (tester) async {
        String dialogResult;
        await _showDialog(tester, [], (word) => dialogResult = word);
        expect(dialogResult, null);

        expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('Shows the dialog according to translations passed as an argument', (tester) async {
        final availableItems = Randomiser.buildRandomStringList();
        
        await _showDialog(tester, availableItems);

        final optionFinders = find.byType(SimpleDialogOption);
        final optionsNumber = availableItems.length;
        for (int i = 0; i < optionsNumber; ++i)
            expect(find.descendant(of: optionFinders.at(i), matching: find.text(availableItems[i])), 
                findsOneWidget);
    });

    testWidgets('Returns chosen translations and hides the dialog', (tester) async {
        final availableItems = Randomiser.buildRandomStringList(minLength: 5, maxLength: 15);
        
        String dialogResult;
        await _showDialog(tester, availableItems, (tr) => dialogResult = tr);

        const int chosenOptionIndex = 1;
        final optionFinders = find.byType(SimpleDialogOption);
        await _tapOption(tester, optionFinders.at(chosenOptionIndex));

        const int anotherChosenOptionIndex = 3;
        await _tapOption(tester, optionFinders.at(anotherChosenOptionIndex));
        await tester.pumpAndSettle();

        await _tapButtonByLabel(tester, 'Done');

        expect(dialogResult.contains(availableItems[chosenOptionIndex]), true);
        expect(dialogResult.contains(availableItems[anotherChosenOptionIndex]), true);
        
        expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('Returns null after tapping on the cancel button', (tester) async {
        final availableItems = Randomiser.buildRandomStringList();

        String dialogResult;
        await _showDialog(tester, availableItems, (word) => dialogResult = word);

        await _tapButtonByLabel(tester, 'Cancel');

        expect(dialogResult, null);
        
        expect(find.byType(SimpleDialog), findsNothing);
    });
}

_showDialog(WidgetTester tester, List<String> items, [Function(String) onDialogClose]) async =>
    SelectorDialogRevealer.showDialog(tester, items, onDialogClose: onDialogClose,
        builder: (context) => new TranslationSelectorDialog(context));
        

Future<void> _tapOption(WidgetTester tester, Finder optionFinder) async {
    expect(optionFinder, findsOneWidget);
    await tester.tap(optionFinder);
}

Future<void> _tapButtonByLabel(WidgetTester tester, String label) async {
    final btnFinder = find.widgetWithText(RaisedButton, label);
    expect(btnFinder, findsOneWidget);
    tester.widget<RaisedButton>(btnFinder).onPressed();

    await tester.pumpAndSettle(Duration(milliseconds: 200));
}
