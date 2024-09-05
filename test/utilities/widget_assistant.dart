import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/presentable_enum.dart';
import 'assured_finder.dart';
import 'localizator.dart';

class WidgetAssistant {
  final WidgetTester tester;

  const WidgetAssistant(this.tester);

  Future<void> pumpAndAnimate([int durationMs = 100]) async {
    final duration = new Duration(milliseconds: durationMs);

    if (!tester.hasRunningAnimations) await tester.pump(duration);

    if (tester.hasRunningAnimations) await tester.pumpAndSettle(duration);
  }

  Future<void> tapWidget(Finder widgetFinder, {bool atCenter = false}) async {
    expect(widgetFinder, findsOneWidget);

    if (atCenter)
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

  Future<void> swipeWidgetLeft(Finder widgetFinder) =>
      _swipeWidget(widgetFinder);

  Future<void> _swipeWidget(Finder widgetFinder, {bool toRight = false}) async {
    expect(widgetFinder, findsOneWidget);

    await tester.fling(
        widgetFinder, new Offset((toRight ? 1 : -1) * 400.0, 0), 400);
    await pumpAndAnimate();
  }

  Future<void> swipeWidgetRight(Finder widgetFinder) =>
      _swipeWidget(widgetFinder, toRight: true);

  Future<Finder> scrollUntilVisible(Finder finder, Type scrollableChildType,
      {bool upwards = false}) async {
    final delta = 100.0 * (upwards ? -1 : 1);
    if (findsNothing.matches(finder, {}))
      try {
        await tester.scrollUntilVisible(finder, delta,
            scrollable: find
                .ancestor(
                    of: find.byType(scrollableChildType),
                    matching: find.byType(Scrollable))
                .first);
      } catch (_) {
        if (findsNothing.matches(finder, {}))
          throw new AssertionError('Nothing was found for the finder: $finder');
      }

    return finder;
  }

  Future<void> changeDropdownItem(
      PresentableEnum fromValue, PresentableEnum toValue) async {
    final locale = Localizator.defaultLocalization;

    final dropDownBtnType = AssuredFinder.typify<DropdownButton<String>>();
    final dropdownFinder =
        find.widgetWithText(dropDownBtnType, fromValue.present(locale));

    await setDropdownItem(dropdownFinder, toValue);
  }

  Future<void> setDropdownItem(
      Finder dropdownFinder, PresentableEnum toValue) async {
    await tapWidget(dropdownFinder);

    await tapWidget(find
        .text(toValue.present(Localizator.defaultLocalization))
        .hitTestable());
  }

  Future<String> enterChangedText(String initialText, {String? changedText}) {
    changedText ??= initialText.substring(1);
    return enterText(find.widgetWithText(TextField, initialText), changedText);
  }

  Future<String> enterText(Finder fieldFinder, String changedText) async {
    await tester.enterText(fieldFinder.first, changedText);

    await pumpAndAnimate();

    return changedText;
  }

  Future<void> finishEnteringText() async {
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await pumpAndAnimate();
  }

  Future<void> navigateBack() async {
    final backBtnFinders = find.byType(BackButton);
    tester.widget<BackButton>(backBtnFinders.first).onPressed?.call();

    await pumpAndAnimate();
  }

  Future<void> navigateBackByOSButton() async {
    final widgetsAppState =
        tester.state(find.byType(WidgetsApp)) as WidgetsBindingObserver;
    await widgetsAppState.didPopRoute();
    await pumpAndAnimate();
  }

  Future<void> scrollDownListView(Finder childFinder,
      {int iterations = 5, void Function()? onIteration}) async {
    int tries = 0;

    while (++tries < iterations) {
      onIteration?.call();

      final ctrl = retrieveListViewScroller(childFinder);
      final position = ctrl.position;
      final newPosition = position.pixels + 300;
      ctrl.jumpTo(newPosition > position.maxScrollExtent
          ? position.maxScrollExtent
          : newPosition);

      await pumpAndAnimate(1500);
    }

    onIteration?.call();
  }

  ScrollController retrieveListViewScroller(Finder childFinder) {
    final listView = tester.widget<ListView>(
        find.ancestor(of: childFinder.first, matching: find.byType(ListView)));
    return listView.controller!;
  }
}
