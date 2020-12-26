import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/dialogs/confirm_dialog.dart';
import '../utilities/dialog_opener.dart';
import '../utilities/randomiser.dart';
import '../utilities/widget_assistant.dart';

void main() {

    testWidgets('Renders a dialog with action buttons returning expected results', 
        (tester) async {

            final actions = {
                Randomiser.nextInt(): Randomiser.nextString(), 
                Randomiser.nextInt(): Randomiser.nextString(),
                Randomiser.nextInt(): Randomiser.nextString() 
            };

            await _testDialogRendering(tester, (title, content) => 
                new ConfirmDialog<int>(title: title, content: content, actions: actions),
                actions);
        });

    testWidgets('Renders a dialog with the OK action returning the true value', 
        (tester) async {

            await _testDialogRendering(tester, (title, content) => 
                ConfirmDialog.buildOkDialog(title: title, content: content),
                ConfirmDialog.okActions);
        });

    testWidgets('Returns null if there have been no actions provided', (tester) async {
        int dialogOutcome = Randomiser.nextInt();
        await _openDialog<int>(tester, new ConfirmDialog<int>(title: Randomiser.nextString(), 
            content: Randomiser.nextString(), actions: {}),
            onDialogClose: (result) => dialogOutcome = result);
        
        expect(dialogOutcome, null);
    });
}

Future<void> _testDialogRendering<T>(WidgetTester tester, 
    ConfirmDialog<T> Function(String title, String content) dialogBuilder, 
    Map<T, String> actions) async {
    final title = Randomiser.nextString();
    final content = Randomiser.nextString();
    
    final expectedAction = Randomiser.nextElement(actions.entries.toList());

    T dialogOutcome;
    await _openDialog(tester, dialogBuilder(title, content), 
        onDialogClose: (result) => dialogOutcome = result);

    _assertDialogVisibility(true);

    _assertTextIsVisible(title);
    _assertTextIsVisible(content);
    actions.values.forEach((label) => _assertTextIsVisible(label));

    await new WidgetAssistant(tester).tapWidget(
        find.widgetWithText(FlatButton, expectedAction.value));

    _assertDialogVisibility(false);
    expect(dialogOutcome, expectedAction.key);
}

Future<void> _openDialog<T>(WidgetTester tester, ConfirmDialog dialog,
    { Function(T) onDialogClose }) => 
        DialogOpener.showDialog<T>(tester, 
            dialogExposer: (context) => dialog.show(context), 
            onDialogClose: onDialogClose);

void _assertDialogVisibility(bool isVisible) => 
    expect(find.byType(AlertDialog), isVisible ? findsOneWidget : findsNothing);

void _assertTextIsVisible(String text) => expect(find.text(text), findsOneWidget);
