import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/presentable_enum.dart';
import 'assured_finder.dart';
import 'localizator.dart';

class WidgetAssistant {
    WidgetTester tester;

    WidgetAssistant(this.tester);
    
    Future<void> pumpAndAnimate([int durationMs]) async {
		final duration = new Duration(milliseconds: durationMs ?? 100);

        if (!tester.hasRunningAnimations)
            await tester.pump(duration);

        if (tester.hasRunningAnimations)
            await tester.pumpAndSettle(duration);
    }

    Future<void> tapWidget(Finder widgetFinder, { bool atCenter }) async {
        expect(widgetFinder, findsOneWidget);
        
		if (atCenter ?? false)
			await tester.tap(widgetFinder);
		else
			await tester.tapAt(tester.getTopLeft(widgetFinder));
		
        await pumpAndAnimate();
    }

    Future<void> pressButtonDirectlyByLabel(String label) async {
        await pressButtonDirectly(find.widgetWithText(ElevatedButton, label));
    }

    Future<void> pressButtonDirectly(Finder btnFinder) async {
        expect(btnFinder, findsOneWidget);
        tester.widget<ElevatedButton>(btnFinder).onPressed?.call();

        await pumpAndAnimate();
    }

    Future<void> swipeWidgetLeft(Finder widgetFinder) => _swipeWidget(widgetFinder);

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
		final delta = 100.0 * ((upwards ?? false) ? -1: 1);
		if (findsNothing.matches(finder, {}))
			await tester.scrollUntilVisible(finder, delta,
				scrollable: find.ancestor(
					of: find.byType(scrollableChildType),
					matching: find.byType(Scrollable)
				).first);

		return finder;
	}

	Future<void> changeDropdownItem(PresentableEnum fromValue, PresentableEnum toValue) async {
		final locale = Localizator.defaultLocalization;

		final dropDownBtnType = AssuredFinder.typify<DropdownButton<String>>();
		final dropdownFinder = find.widgetWithText(dropDownBtnType, 
			fromValue.present(locale));
		
		await setDropdownItem(dropdownFinder, toValue);
	}

	Future<void> setDropdownItem(Finder dropdownFinder, PresentableEnum toValue) async {
		await tapWidget(dropdownFinder);

		await tapWidget(find.text(toValue.present(Localizator.defaultLocalization)).hitTestable());
	}

	Future<String> enterChangedText(String initialText, { String changedText }) {
		changedText ??= initialText.substring(1);
		return enterText(find.widgetWithText(TextField, initialText), changedText);
	}

	Future<String> enterText(Finder fieldFinder, String changedText) async {
		await tester.enterText(fieldFinder, changedText);
		
		await pumpAndAnimate();

		return changedText;
	}
}
