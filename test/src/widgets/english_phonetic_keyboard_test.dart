import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/widgets/input_keyboard.dart';
import 'package:language_cards/src/widgets/phonetic_keyboard.dart';
import 'package:language_cards/src/widgets/keyboarded_field.dart';
import '../../mocks/root_widget_mock.dart';
import '../../testers/card_editor_tester.dart';
import '../../utilities/randomiser.dart';

void main() {
    
    testWidgets('Shows a keyboard with English phonetic symbols', (tester) async {
        final foundResult = await _createKeyboard(tester);
        
        _assertKeyboardIsHidden();
        await _showKeyboard(tester, foundResult);

        _getEmptyKeyboard().symbols.forEach((symbol) { 
            expect(find.widgetWithText(InkWell, symbol), findsWidgets);
        });
    });

    testWidgets('Removes a phonetic symbol by clicking on the backspace key', (tester) async {
        await _createKeyboard(tester, show: true);
        
        final expectedSymbols = await new CardEditorTester(tester).enterRandomTranscription();
        var input = expectedSymbols.join('');

        do {
            expect(_findEditableText(input), findsOneWidget);
            
            await _tapIconKey(tester, Icons.backspace);
            expect(_findEditableText(input), findsNothing);

            expectedSymbols.removeLast();
            input = expectedSymbols.join('');
        } while (input.isNotEmpty);

        await _tapIconKey(tester, Icons.backspace);
    });

    testWidgets('Hides a keyboard by clicking on the done key', (tester) async {
        await _createKeyboard(tester, show: true);

        final expectedSymbols = await new CardEditorTester(tester).enterRandomTranscription();

        await _tapIconKey(tester, Icons.done);

        final input = expectedSymbols.join('');
        final foundResult = _findEditableText(input);
        expect(foundResult, findsOneWidget);

        _assertKeyboardIsHidden();
        expect((tester.widget(foundResult) as EditableText).focusNode.hasFocus, false);

        await tester.pump(const Duration(milliseconds: 100));
    });
}

Future<Finder> _createKeyboard(WidgetTester tester, { bool show }) async {
    final fieldKey = new Key(Randomiser.nextString());
    final fieldWithKeyboard = new KeyboardedField(
		Language.english, new FocusNode(), '', key: fieldKey);

    await tester.pumpWidget(RootWidgetMock.buildAsAppHome(child: fieldWithKeyboard));

    final foundResult = find.byKey(fieldKey);
    expect(foundResult, findsWidgets);

    if (show == true)
        await _showKeyboard(tester, foundResult);

    return foundResult;
}

Future<void> _showKeyboard(WidgetTester tester, Finder foundKeyboard) async {
    await tester.showKeyboard(foundKeyboard);
    await tester.pump();
}

void _assertKeyboardIsHidden() {
    expect(find.byType(InputKeyboard), findsNothing);
    _getEmptyKeyboard().symbols.forEach((symbol) => 
        expect(find.text(symbol), findsNothing));
} 

Future<void> _tapIconKey(WidgetTester tester, IconData icon) async {
    final foundKey = find.widgetWithIcon(InkWell, icon);
    expect(foundKey, findsOneWidget);

    await tester.tap(foundKey);
    await tester.pump(const Duration(milliseconds: 200));
}

Finder _findEditableText(String input) => find.descendant(of: find.byType(EditableText), 
    matching: find.text(input), matchRoot: true);

InputKeyboard _getEmptyKeyboard() => PhoneticKeyboard.getLanguageSpecific((_) => _);
