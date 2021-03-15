import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/dialogs/confirm_dialog.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/dialog_opener.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/widget_assistant.dart';

void main() {

    testWidgets('Renders a dialog with confirmation/cancellation buttons returning expected results', 
        (tester) async {

			final expectedTitle = Randomiser.nextString();
            await _testDialogRendering(tester, (title, content) => 
                new ConfirmDialog(title: title, content: content, 
					confirmationLabel: expectedTitle), 
					{ true: expectedTitle, false: _cancellationLabel });
        });

    testWidgets('Renders a dialog with the only an OK button returning the true value', 
        (tester) async {

            await _testDialogRendering(tester, (title, content) => 
                new ConfirmDialog.ok(title: title, content: content),
                { true: Localizator.defaultLocalization.confirmDialogOkButtonLabel });

		    _assertTextVisibility(_cancellationLabel, isVisible: false);
        });
}

Future<void> _testDialogRendering<T>(WidgetTester tester, 
    ConfirmDialog Function(String title, String content) dialogBuilder, 
	Map<bool, String> actions) async {

    final title = Randomiser.nextString();
    final content = Randomiser.nextString();
    
    final expectedAction = Randomiser.nextElement(actions.entries.toList());

    bool dialogOutcome;
    await _openDialog(tester, dialogBuilder(title, content), 
        onDialogClose: (result) => dialogOutcome = result);

    _assertDialogVisibility(true);

    _assertTextVisibility(title, isVisible: true);
    _assertTextVisibility(content, isVisible: true);
    actions.values.forEach((label) => _assertTextVisibility(label, isVisible: true));

    await new WidgetAssistant(tester).tapWidget(
        find.widgetWithText(ElevatedButton, expectedAction.value));

    _assertDialogVisibility(false);
    expect(dialogOutcome, expectedAction.key);
}

Future<void> _openDialog(WidgetTester tester, ConfirmDialog dialog,
    { Function(bool) onDialogClose }) => 
        DialogOpener.showDialog<bool>(tester, 
            dialogExposer: (context) => dialog.show(context), 
            onDialogClose: onDialogClose);

void _assertDialogVisibility(bool isVisible) => 
	AssuredFinder.findOne(type: AlertDialog, shouldFind: isVisible);

void _assertTextVisibility(String text, { bool isVisible }) => 
	AssuredFinder.findOne(label: text, shouldFind: isVisible);

String get _cancellationLabel => 
	Localizator.defaultLocalization.cancellableDialogCancellationButtonLabel;
