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

    Future<void> pumpAndAnimate([int durationMs]) async {
		final duration = new Duration(milliseconds: durationMs ?? 100);

        if (!tester.hasRunningAnimations)
            await tester.pump(duration);

        if (tester.hasRunningAnimations)
            await tester.pumpAndSettle(duration);
    }

    Future<void> tapWidget(Finder widgetFinder, { bool atCenter }) async {
        expect(widgetFinder, findsOneWidget);
        
		if ((atCenter ?? false))
			await tester.tap(widgetFinder);
		else
			await tester.tapAt(tester.getTopLeft(widgetFinder));
		
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

	Future<Finder> scrollUntilVisible(Finder finder, Type scrollableChildType, 
		{ bool upwards }
	) async {
		try {
			final delta = 100.0 * ((upwards ?? false) ? -1: 1);
			if (findsNothing.matches(finder, {}))
				await tester.scrollUntilVisible(finder, delta,
					scrollable: find.ancestor(
						of: find.byType(scrollableChildType),
						matching: find.byType(Scrollable)
					).first);
		}
		on StateError catch (_) { }

		return finder;
	}
}
