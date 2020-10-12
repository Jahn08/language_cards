import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/dialogs/confirm_dialog.dart';
import '../utilities/dialog_opener.dart';
import '../utilities/randomiser.dart';
import '../utilities/widget_assistant.dart';

void main() {

    testWidgets('Renders a dialog with action buttons returning expected results', 
        (tester) async {
            final title = Randomiser.nextString();
            final content = Randomiser.nextString();
            final actions = {
                Randomiser.nextInt(): Randomiser.nextString(), 
                Randomiser.nextInt(): Randomiser.nextString(),
                Randomiser.nextInt(): Randomiser.nextString() 
            };
            final expectedAction = Randomiser.nextElement(actions.entries.toList());

            int dialogOutcome;
            await _openDialog(tester, title, content, actions,
                onDialogClose: (result) => dialogOutcome = result);

            _assertDialogVisibility(true);

            _assertTextIsVisible(title);
            _assertTextIsVisible(content);
            actions.values.forEach((label) => _assertTextIsVisible(label));

            await new WidgetAssistant(tester).tapWidget(
                find.widgetWithText(FlatButton, expectedAction.value));
        
            _assertDialogVisibility(false);
            expect(dialogOutcome, expectedAction.key);
        });

    testWidgets('Returns null if there have been no actions provided', (tester) async {
        int dialogOutcome = Randomiser.nextInt();
        await _openDialog(tester, Randomiser.nextString(), Randomiser.nextString(), 
            {}, onDialogClose: (result) => dialogOutcome = result);
        
        expect(dialogOutcome, null);
    });
}

Future<void> _openDialog(WidgetTester tester, String title, String content, 
    Map<int, String> actions, { Function(int) onDialogClose }) => 
        DialogOpener.showDialog<int>(tester, 
            dialogExposer: (context) => new ConfirmDialog<int>(title: title, 
                content: content, actions: actions).show(context), 
            onDialogClose: onDialogClose);

void _assertDialogVisibility(bool isVisible) => 
    expect(find.byType(AlertDialog), isVisible ? findsOneWidget : findsNothing);

void _assertTextIsVisible(String text) => expect(find.text(text), findsOneWidget);
