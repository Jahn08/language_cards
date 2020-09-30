import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:language_cards/src/dialogs/selector_dialog.dart';
import '../utilities/randomiser.dart';
import '../utilities/test_root_widget.dart';
import '../utilities/widget_assistant.dart';

class SelectorDialogTester<T> {
    final WidgetTester tester;

    final SelectorDialog<T> Function(BuildContext) _dialogBuilder;

    SelectorDialogTester(this.tester, 
        SelectorDialog<T> Function(BuildContext) dialogBuilder):
        _dialogBuilder = dialogBuilder;

    Future<void> testCancelling(List<T> items,) async {
        T dialogResult;
        await showDialog(items, (item) => dialogResult = item);

        final assistant = new WidgetAssistant(tester);
        await assistant.pressButtonDirectlyByLabel('Cancel');

        expect(dialogResult, null);
        expect(find.byType(SimpleDialog), findsNothing);
    }

    Future<void> showDialog(List<T> items, [Function(T) onDialogClose]) async =>
        await _showDialog(items, onDialogClose: onDialogClose,
            builder: _dialogBuilder);

    Future<void> _showDialog(List<T> items, { 
        @required SelectorDialog Function(BuildContext) builder, 
        Function(T) onDialogClose 
    }) async {
        BuildContext context;
        final dialogBtnKey = new Key(Randomiser.nextString());
        await tester.pumpWidget(TestRootWidget.buildAsAppHome(
            onBuilding: (inContext) => context = inContext,
            child: new RaisedButton(
                key: dialogBtnKey,
                onPressed: () async {
                    final outcome = await builder(context).show(items);
                    onDialogClose?.call(outcome);
                })
            )
        );

        final foundDialogBtn = find.byKey(dialogBtnKey);
        expect(foundDialogBtn, findsOneWidget);
            
        await tester.tap(foundDialogBtn);
        await tester.pump(new Duration(milliseconds: 200));
    }

    Future<void> testTappingItem(List<T> items) async {
        T dialogResult;
        await showDialog(items, (item) => dialogResult = item);

        final optionFinders = find.byType(SimpleDialogOption);
        final chosenOptionIndex = Randomiser.nextInt(
            tester.widgetList(optionFinders).length);
        final chosenOptionFinder = optionFinders.at(chosenOptionIndex);
        expect(chosenOptionFinder, findsOneWidget);

        await new WidgetAssistant(tester).tapWidget(chosenOptionFinder);

        expect(dialogResult, items[chosenOptionIndex]);
        expect(find.byType(SimpleDialog), findsNothing);
    }

    Future<void> testRenderingOptions(List<T> items, 
        Function(Finder, T) optionChecker, Type optionTileType) async {
        await showDialog(items);

        final optionFinders = find.ancestor(of: find.byType(optionTileType), 
            matching: find.byType(SimpleDialogOption));
        final foundOptions = tester.widgetList(optionFinders);
        expect(foundOptions.length, items.length);

        final optionsNumber = items.length;
        for (int i = 0; i < optionsNumber; ++i)
            optionChecker(optionFinders.at(i), items[i]);
    }
}
