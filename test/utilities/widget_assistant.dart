import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/widgets/english_phonetic_keyboard.dart';
import './randomiser.dart';

class WidgetAssistant {
    WidgetTester tester;

    WidgetAssistant(this.tester);

    Future<List<String>> enterRandomTranscription() async {
        const symbols = EnglishPhoneticKeyboard.phonetic_symbols;
        final expectedSymbols = [Randomiser.nextElement(symbols),
            Randomiser.nextElement(symbols), Randomiser.nextElement(symbols)];

        for (final symbol in expectedSymbols)
            await _tapSymbolKey(symbol);

        return expectedSymbols;
    }

    Future<void> _tapSymbolKey(String symbol) async {
        final foundKey = find.widgetWithText(InkWell, symbol);
        expect(foundKey, findsOneWidget);

        await tester.tap(foundKey);
        await pumpAndAnimate();
    }

    Future<void> pumpAndAnimate() async {
        if (!tester.hasRunningAnimations)
            await tester.pump(new Duration(milliseconds: 100));

        if (tester.hasRunningAnimations)
            await tester.pumpAndSettle();
    }

    Future<void> tapWidget(Finder widgetFinder) async {
        expect(widgetFinder, findsOneWidget);
        await tester.tap(widgetFinder);

        await pumpAndAnimate();
    }

    Future<void> pressButtonDirectlyByLabel(String label) async {
        await pressButtonDirectly(find.widgetWithText(RaisedButton, label));
    }

    Future<void> pressButtonDirectly(Finder btnFinder) async {
        expect(btnFinder, findsOneWidget);
        tester.widget<RaisedButton>(btnFinder).onPressed();

        await pumpAndAnimate();
    }

    Future<void> swipeWidgetLeft(Finder widgetFinder) =>
        _swipeWidget(widgetFinder, toRight: false);

    Future<void> _swipeWidget(Finder widgetFinder, { bool toRight = false }) async {
        expect(widgetFinder, findsOneWidget);

        await tester.fling(widgetFinder, new Offset((toRight ? 1: -1) * 400.0, 0), 400);
        await pumpAndAnimate();
    }

    Future<void> swipeWidgetRight(Finder widgetFinder) =>
        _swipeWidget(widgetFinder, toRight: true);
}
