import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/dialogs/translation_selector_dialog.dart';
import '../../testers/dialog_tester.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/widget_assistant.dart';
import '../../testers/selector_dialog_tester.dart';

void main() {

    testWidgets('Returns null for an empty list of translations', (tester) async {
        final dialogTester = new SelectorDialogTester(tester, _buildDialog);

        String dialogResult;
        await dialogTester.showDialog([], (tr) => dialogResult = tr);

        expect(dialogResult, null);
		new DialogTester().assureDialog(shouldFind: false);
    });

    testWidgets('Shows the translation dialog according to items passed as an argument', 
        (tester) async {
            final availableItems = Randomiser.nextStringList();
            final dialogTester = new SelectorDialogTester(tester, _buildDialog);
            await dialogTester.testRenderingOptions(availableItems, (finder, option) {
                expect(find.descendant(of: finder, matching: find.text(option)), 
                    findsOneWidget);
            }, CheckboxListTile); 
        });

    testWidgets('Returns chosen translations and hides the dialog', (tester) async {
        final availableItems = Randomiser.nextStringList(minLength: 5, maxLength: 15);
        
        final dialogTester = new SelectorDialogTester(tester, _buildDialog);
        
        String dialogResult;
        await dialogTester.showDialog(availableItems, (tr) => dialogResult = tr);

        const int chosenOptionIndex = 1;
        final optionFinders = find.byType(SimpleDialogOption);

        final assistant = new WidgetAssistant(tester);
        await assistant.tapWidget(optionFinders.at(chosenOptionIndex));

        const int anotherChosenOptionIndex = 3;
        await assistant.tapWidget(optionFinders.at(anotherChosenOptionIndex));

        await _pressDoneButton(tester);

        expect(dialogResult.contains(availableItems[chosenOptionIndex]), true);
        expect(dialogResult.contains(availableItems[anotherChosenOptionIndex]), true);
        
		new DialogTester().assureDialog(shouldFind: false);
    });

    testWidgets('Returns all translations chosen by ticking the title checkbox', (tester) async {
        final availableItems = Randomiser.nextStringList(minLength: 3, maxLength: 7);
        
        final dialogTester = new SelectorDialogTester(tester, _buildDialog);
        
        String dialogResult;
        await dialogTester.showDialog(availableItems, (tr) => dialogResult = tr);

        final assistant = new WidgetAssistant(tester);
        await assistant.tapWidget(find.byType(CheckboxListTile).first);

        expect(tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .every((checkbox) => checkbox.value), true);

        await _pressDoneButton(tester);

        expect(availableItems.every((op) => dialogResult.contains(op)), true);
    });

    testWidgets('Returns no translation after choosing nothing by clicking the title checkbox twice',
        (tester) async {
            final dialogTester = new SelectorDialogTester(tester, _buildDialog);
            
            String dialogResult;
            await dialogTester.showDialog(Randomiser.nextStringList(minLength: 3, maxLength: 7), 
                (tr) => dialogResult = tr);

            final titleOptionFinder = find.byType(CheckboxListTile);
            final assistant = new WidgetAssistant(tester);
            await assistant.tapWidget(titleOptionFinder.first);

            await assistant.tapWidget(titleOptionFinder.first);

            expect(tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
                .every((checkbox) => !checkbox.value), true);

            await _pressDoneButton(tester);
            expect(dialogResult.isEmpty, true);
        });

    testWidgets('Returns null after tapping the cancel button of the translation dialog', 
        (tester) async {
            final dialogTester = new SelectorDialogTester(tester, _buildDialog);
            await dialogTester.testCancelling(Randomiser.nextStringList());
        });
}

TranslationSelectorDialog _buildDialog(BuildContext context) => 
    new TranslationSelectorDialog(context);

Future<void> _pressDoneButton(WidgetTester tester) async => 
    await new WidgetAssistant(tester).pressButtonDirectlyByLabel('Done');
