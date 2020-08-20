import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:language_cards/src/widgets/english_phonetic_keyboard.dart';
import 'package:language_cards/src/widgets/keyboarded_field.dart';
import '../utilities/randomiser.dart';
import '../utilities/test_root_widget.dart';

void main() {
    testWidgets('Shows a keyboard with English phonetic symbols', (tester) async {
        final foundResult = await _createKeyboard(tester);
        
        expect(find.byType(EnglishPhoneticKeyboard), findsNothing);
        EnglishPhoneticKeyboard.PHONETIC_SYMBOLS.forEach((symbol) { 
            expect(find.text(symbol), findsNothing);
        });

        await _showKeyboard(tester, foundResult);

        EnglishPhoneticKeyboard.PHONETIC_SYMBOLS.forEach((symbol) { 
            expect(find.widgetWithText(InkWell, symbol), findsWidgets);
        });
    });

    testWidgets('Removes a phonetic symbol by clicking on the backspace key', (tester) async {
        await _createKeyboard(tester, show: true);
        
        final expectedSymbols = await _enterRandomSymbols(tester);
        var input = expectedSymbols.join('');

        do {
            expect(_findEditableText(input), findsOneWidget);
            
            await _tapIconKey(tester, Icons.backspace);
            expect(_findEditableText(input), findsNothing);

            expectedSymbols.removeLast();
            input = expectedSymbols.join('');
        } while (input.length > 0);

        await _tapIconKey(tester, Icons.backspace);
    });

    testWidgets('Accepts entered text by clicking on the done key', (tester) async {
        await _createKeyboard(tester, show: true);

        final expectedSymbols = await _enterRandomSymbols(tester);

        await _tapIconKey(tester, Icons.done);

        var input = expectedSymbols.join('');

        final foundResult = _findEditableText(input);
        expect(foundResult, findsOneWidget);

        expect((tester.widget(foundResult) as EditableText).focusNode.hasFocus, false);
    });
}

Future<Finder> _createKeyboard(WidgetTester tester, { bool show }) async {
    final fieldKey = new Key(Randomiser.buildRandomString());
    final fieldWithKeyboard = new KeyboardedField(new EnglishPhoneticKeyboard(), '', 
        key: fieldKey);

    await tester.pumpWidget(new MaterialApp(
        home: new TestRootWidget(child: fieldWithKeyboard)));

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

Future<List<String>> _enterRandomSymbols(WidgetTester tester) async {
    const symbols = EnglishPhoneticKeyboard.PHONETIC_SYMBOLS;
    final expectedSymbols = [Randomiser.getRandomElement(symbols),
        Randomiser.getRandomElement(symbols), Randomiser.getRandomElement(symbols)];

    for (final symbol in expectedSymbols)
        await _tapSymbolKey(tester, symbol);

    return expectedSymbols;
}

Future<void> _tapSymbolKey(WidgetTester tester, String symbol) async {
    final foundKey = find.widgetWithText(InkWell, symbol);
    expect(foundKey, findsOneWidget);

    await tester.tap(foundKey);
    await tester.pump(new Duration(milliseconds: 200));
}

Future<void> _tapIconKey(WidgetTester tester, IconData icon) async {
    final foundKey = find.widgetWithIcon(InkWell, icon);
    expect(foundKey, findsOneWidget);

    await tester.tap(foundKey);
    await tester.pump(new Duration(milliseconds: 200));
}

Finder _findEditableText(String input) => find.descendant(of: find.byType(EditableText), 
    matching: find.text(input), matchRoot: true);
