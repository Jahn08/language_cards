import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:language_cards/src/dialogs/selector_dialog.dart';
import 'package:language_cards/src/widgets/dialog_list_view.dart';
import '../utilities/dialog_opener.dart';
import '../utilities/randomiser.dart';
import '../utilities/widget_assistant.dart';
import 'cancellable_dialog_tester.dart';
import 'dialog_tester.dart';

class SelectorDialogTester<T> extends CancellableDialogTester {
  final SelectorDialog<T> Function(BuildContext) _dialogBuilder;

  const SelectorDialogTester(
      super.tester, SelectorDialog<T> Function(BuildContext) dialogBuilder)
      : _dialogBuilder = dialogBuilder;

  Future<void> testCancelling(List<T> items) async {
    T? dialogResult;
    await showDialog(items, (item) => dialogResult = item);

    await assureCancellingDialog();

    expect(dialogResult, null);
  }

  Future<void> showDialog(List<T> items, [Function(T?)? onDialogClose]) =>
      DialogOpener.showDialog<T>(tester,
          dialogExposer: (context) => _dialogBuilder(context).show(items),
          onDialogClose: onDialogClose);

  Future<void> testTappingItem(List<T> items) async {
    T? dialogResult;
    await showDialog(items, (item) => dialogResult = item);

    final expectedDialogResult = await assureTappingItem(tester, items);
    expect(dialogResult, expectedDialogResult);
  }

  Future<void> testRenderingOptions(List<T> items,
      Function(Finder, T) optionChecker, Type optionTileType) async {
    await showDialog(items);

    assureRenderedOptions(tester, items, optionChecker, optionTileType);
  }

  static void assureRenderedOptions<T>(WidgetTester tester, List<T> items,
      Function(Finder, T) optionChecker, Type optionTileType) {
    final initialOptionIndex = findsNothing.matches(
            find.descendant(
                of: find.byType(ShrinkableSimpleDialogOption).first,
                matching: find.byType(optionTileType)),
            {})
        ? 0
        : 1;
    final optionFinders = find.ancestor(
        of: find.byType(optionTileType),
        matching: find.byType(ShrinkableSimpleDialogOption));
    final foundOptions = tester.widgetList(optionFinders);
    expect(foundOptions.length - initialOptionIndex, items.length);

    final optionsNumber = items.length;
    for (int i = initialOptionIndex; i < optionsNumber; ++i)
      optionChecker(optionFinders.at(i), items[i - initialOptionIndex]);
  }

  static Future<T> assureTappingItem<T>(WidgetTester tester, List<T> items) async {
    final optionFinders = find.byType(ShrinkableSimpleDialogOption);
    final itemIndex = Randomiser.nextInt(items.length);
    final chosenOptionIndex = itemIndex + 1;
    final chosenOptionFinder = optionFinders.at(chosenOptionIndex);
    expect(chosenOptionFinder, findsOneWidget);

    await new WidgetAssistant(tester).tapWidget(chosenOptionFinder);

    DialogTester.assureDialog(shouldFind: false);
    return items[itemIndex];
  }
}
