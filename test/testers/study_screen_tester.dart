import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import '../utilities/widget_assistant.dart';

class StudyScreenTester {
  final WidgetAssistant assistant;

  StudyScreenTester(this.assistant);

  Future<void> goThroughCardList(int listLength,
      {bool byClickingButton, void Function() onNextCard}) async {
    int index = 0;
    do {
      await ((byClickingButton ?? false)
          ? goToNextCardByClick()
          : goToNextCardBySwipe());

      onNextCard?.call();
    } while (++index < listLength);
  }

  Future<void> goToNextCardBySwipe() =>
      assistant.swipeWidgetLeft(findCardWidget());

  static Finder findCardWidget() => find.byType(PageView);

  Future<void> goToNextCardByClick() =>
      assistant.tapWidget(find.widgetWithText(ElevatedButton, 'Next'));

  Future<void> goToPreviousCard() =>
      assistant.swipeWidgetRight(findCardWidget());

  List<StoredPack> takeEnoughCards(List<StoredPack> packs) {
    int cardsNumber = 0;
    return packs.takeWhile((p) {
      if (cardsNumber > 3) return false;

      cardsNumber += p.cardsNumber;
      return true;
    }).toList();
  }
}
