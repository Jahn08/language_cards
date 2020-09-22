import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/dialogs/translation_selector_dialog.dart';
import '../utilities/randomiser.dart';
import '../utilities/selector_dialog_revealer.dart';
import '../utilities/widget_assistant.dart';

void main() {

    testWidgets('Returns null for for an empty list of translations', (tester) async {
        String dialogResult;
        await _showDialog(tester, [], (word) => dialogResult = word);
        expect(dialogResult, null);

        expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('Shows the dialog according to translations passed as an argument', (tester) async {
        final availableItems = Randomiser.nextStringList();
        
        await _showDialog(tester, availableItems);

        final optionFinders = find.byType(SimpleDialogOption);
        final optionsNumber = availableItems.length;
        for (int i = 0; i < optionsNumber; ++i)
            expect(find.descendant(of: optionFinders.at(i), matching: find.text(availableItems[i])), 
                findsOneWidget);
    });

    testWidgets('Returns chosen translations and hides the dialog', (tester) async {
        final availableItems = Randomiser.nextStringList(minLength: 5, maxLength: 15);
        
        String dialogResult;
        await _showDialog(tester, availableItems, (tr) => dialogResult = tr);

        const int chosenOptionIndex = 1;
        final optionFinders = find.byType(SimpleDialogOption);
        await _tapOption(tester, optionFinders.at(chosenOptionIndex));

        const int anotherChosenOptionIndex = 3;
        await _tapOption(tester, optionFinders.at(anotherChosenOptionIndex));
        await tester.pumpAndSettle();

        await _pressDoneButton(tester);

        expect(dialogResult.contains(availableItems[chosenOptionIndex]), true);
        expect(dialogResult.contains(availableItems[anotherChosenOptionIndex]), true);
        
        expect(find.byType(SimpleDialog), findsNothing);
    });

    testWidgets('Returns all translations chosen by ticking the title checkbox', (tester) async {
        final availableItems = Randomiser.nextStringList(minLength: 3, maxLength: 7);
        
        String dialogResult;
        await _showDialog(tester, availableItems, (tr) => dialogResult = tr);

        final titleOptionFinder = find.byType(CheckboxListTile);
        await _tapOption(tester, titleOptionFinder.first);
        await tester.pumpAndSettle();

        expect(tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .every((checkbox) => checkbox.value), true);

        await _pressDoneButton(tester);

        expect(availableItems.every((op) => dialogResult.contains(op)), true);
    });

    testWidgets('Returns emptiness after choosing nothing by clicking the title checkbox twice',
        (tester) async {
            final availableItems = Randomiser.nextStringList(minLength: 3, maxLength: 7);
            
            String dialogResult;
            await _showDialog(tester, availableItems, (tr) => dialogResult = tr);

            final titleOptionFinder = find.byType(CheckboxListTile);
            await _tapOption(tester, titleOptionFinder.first);
            await tester.pumpAndSettle();

            await _tapOption(tester, titleOptionFinder.first);
            await tester.pumpAndSettle();

            expect(tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
                .every((checkbox) => !checkbox.value), true);

            await _pressDoneButton(tester);
            expect(dialogResult.isEmpty, true);
        });

    testWidgets('Returns null after tapping on the cancel button', (tester) async {
        final availableItems = Randomiser.nextStringList();

        String dialogResult;
        await _showDialog(tester, availableItems, (word) => dialogResult = word);

        await new WidgetAssistant(tester).pressButtonDirectlyByLabel('Cancel');

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

Future<void> _pressDoneButton(WidgetTester tester) async => 
    await new WidgetAssistant(tester).pressButtonDirectlyByLabel('Done');
