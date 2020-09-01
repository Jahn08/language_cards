import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/widgets/english_phonetic_keyboard.dart';
import './randomiser.dart';

class WidgetAssistant {
    WidgetTester tester;

    WidgetAssistant(this.tester);

    Future<List<String>> enterRandomTranscription() async {
        const symbols = EnglishPhoneticKeyboard.PHONETIC_SYMBOLS;
        final expectedSymbols = [Randomiser.getRandomElement(symbols),
            Randomiser.getRandomElement(symbols), Randomiser.getRandomElement(symbols)];

        for (final symbol in expectedSymbols)
            await _tapSymbolKey(symbol);

        return expectedSymbols;
    }

    Future<void> _tapSymbolKey(String symbol) async {
        final foundKey = find.widgetWithText(InkWell, symbol);
        expect(foundKey, findsOneWidget);

        await tester.tap(foundKey);
        await tester.pumpAndSettle();
    }

    Future<void> tapWidget(Finder widgetFinder) async {
        expect(widgetFinder, findsOneWidget);
        await tester.tap(widgetFinder);
        await tester.pumpAndSettle();
    }

    Future<void> pressButtonDirectlyByLabel(String label) async {
        await pressButtonDirectly(find.widgetWithText(RaisedButton, label));
    }

    Future<void> pressButtonDirectly(Finder btnFinder) async {
        expect(btnFinder, findsOneWidget);
        tester.widget<RaisedButton>(btnFinder).onPressed();

        await tester.pumpAndSettle();
    }
}
