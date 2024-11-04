import 'package:flutter/material.dart' hide NavigationBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/presentable_enum.dart';
import 'package:language_cards/src/blocs/settings_bloc.dart';
import 'package:language_cards/src/data/asset_dictionary_provider.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/models/user_params.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/study_screen.dart';
import 'package:language_cards/src/widgets/navigation_bar.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/root_widget_mock.dart';
import '../../mocks/speaker_mock.dart';
import '../../mocks/word_storage_mock.dart';
import '../../testers/cancellable_dialog_tester.dart';
import '../../testers/card_editor_tester.dart';
import '../../testers/dialog_tester.dart';
import '../../testers/preferences_tester.dart';
import '../../testers/selector_dialog_tester.dart';
import '../../testers/study_screen_tester.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/storage_fetcher.dart';
import '../../utilities/widget_assistant.dart';

enum _CardNavigationWay {
  bySwipe,

  byArrow
}

void main() {
  setUp(() => PreferencesTester.saveDefaultUserParams());

  testWidgets(
      'Renders card data along with buttons for configuring the study mode',
      (tester) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    expect(
        find.descendant(
            of: find.byType(ElevatedButton, skipOffstage: false),
            matching: find.byType(Text, skipOffstage: false)),
        findsNWidgets(4));

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));
    _assureFrontSideRendering(tester, packs, cards);
  });

  testWidgets(
      'Renders the study mode buttons in accordance with user preferences',
      (tester) async {
    final expectedParams = await PreferencesTester.saveNonDefaultUserParams();

    await _pumpScreen(tester, new PackStorageMock());

    final locale = Localizator.defaultLocalization;
    final studyParams = expectedParams.studyParams;
    expect(_findButtonEndingWithText(studyParams.direction.present(locale)),
        findsOneWidget);
    expect(_findButtonEndingWithText(studyParams.cardSide.present(locale)),
        findsOneWidget);
  });

  testWidgets(
      'Renders a name for a chosen sorting mode when clicking on the button',
      (tester) async {
    await _pumpScreen(tester, new PackStorageMock());

    await _testChangingStudyModes(
        tester, StudyDirection.values.toList()..add(StudyDirection.forward));
  });

  testWidgets(
      'Renders a name for a chosen card side mode when clicking on the button',
      (tester) async {
    await _pumpScreen(tester, new PackStorageMock());

    await _testChangingStudyModes(
        tester, CardSide.values.toList()..add(CardSide.front));
  });

  final cardNavigationWay =
      ValueVariant<_CardNavigationWay>(_CardNavigationWay.values.toSet());

  testWidgets('Renders cards once when navigating with the forward sorting',
      (tester) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));

    final assistant = new WidgetAssistant(tester);
    final screenTester = new StudyScreenTester(assistant);

    final shouldSwipe =
        cardNavigationWay.currentValue! == _CardNavigationWay.bySwipe;
    await _goToNextCard(screenTester, shouldSwipe: shouldSwipe);

    _assureFrontSideRendering(tester, packs, cards, expectedIndex: 1);

    await screenTester.goToPreviousCard();
    _assureFrontSideRendering(tester, packs, cards);

    final shownCards = <StoredWord>[cards.first];
    await screenTester.goThroughCardList(cards.length - 1,
        byClickingButton: !shouldSwipe,
        onNextCard: () => shownCards.add(_getShownCard(tester, cards)));

    expect(cards.length, new Set.from(shownCards).length);
  }, variant: cardNavigationWay);

  testWidgets('Renders cards once when navigating with the backward sorting',
      (tester) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage), true);

    final assistant = new WidgetAssistant(tester);
    await _pressButtonEndingWithText(assistant,
        StudyDirection.forward.present(Localizator.defaultLocalization));

    final shouldSwipe =
        cardNavigationWay.currentValue! == _CardNavigationWay.bySwipe;

    final screenTester = new StudyScreenTester(assistant);
    await _goToNextCard(screenTester, shouldSwipe: shouldSwipe);
    _assureFrontSideRendering(tester, packs, cards, expectedIndex: 1);

    await screenTester.goToPreviousCard();
    _assureFrontSideRendering(tester, packs, cards);

    final shownCards = <StoredWord>[cards.first];
    await screenTester.goThroughCardList(cards.length - 1,
        byClickingButton: !shouldSwipe,
        onNextCard: () => shownCards.add(_getShownCard(tester, cards)));

    expect(cards.length, new Set.from(shownCards).length);
  }, variant: cardNavigationWay);

  testWidgets('Renders cards once when navigating with the random sorting',
      (tester) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards =
        await _fetchPackedCards(tester, packs, packStorage.wordStorage);

    final assistant = new WidgetAssistant(tester);

    for (final sortMode in [StudyDirection.forward, StudyDirection.backward])
      await _pressButtonEndingWithText(
          assistant, sortMode.present(Localizator.defaultLocalization));

    final shownCards = <StoredWord>[];
    final firstCard = _getShownCard(tester, cards);
    shownCards.add(firstCard);

    final shouldSwipe =
        cardNavigationWay.currentValue! == _CardNavigationWay.bySwipe;

    final screenTester = new StudyScreenTester(assistant);
    await _goToNextCard(screenTester, shouldSwipe: shouldSwipe);

    final nextCard = _getShownCard(tester, cards);

    _assureFrontSideRendering(tester, packs, cards,
        card: nextCard, expectedIndex: 1);

    await screenTester.goToPreviousCard();

    _assureFrontSideRendering(tester, packs, cards, card: firstCard);

    await screenTester.goThroughCardList(cards.length - 1,
        byClickingButton: !shouldSwipe,
        onNextCard: () => shownCards.add(_getShownCard(tester, cards)));

    expect(cards.length, new Set.from(shownCards).length);
  }, variant: cardNavigationWay);

  testWidgets(
      'Shows a dialog after finishing a study cycle, then closes it and starts afresh',
      (tester) async {
    final packStorage = new PackStorageMock();

    final assistant = new WidgetAssistant(tester);
    final screenTester = new StudyScreenTester(assistant);
    final packs = screenTester
        .takeEnoughCards(await _fetchNamedPacks(tester, packStorage));
    await _pumpScreen(tester, packStorage, packs);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));

    await screenTester.goThroughCardList(cards.length);

    final dialogBtnFinder = _assureDialogBtnExistence(true);
    await assistant.tapWidget(dialogBtnFinder);

    _assureFrontSideRendering(tester, packs, cards);

    _assureDialogBtnExistence(false);
  });

  testWidgets(
      'Shows no dialog after going backward from the first card to the last one',
      (tester) async {
    final packStorage = new PackStorageMock();

    final assistant = new WidgetAssistant(tester);
    final screenTester = new StudyScreenTester(assistant);
    final packs = screenTester
        .takeEnoughCards(await _fetchNamedPacks(tester, packStorage));
    await _pumpScreen(tester, packStorage, packs);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));
    await screenTester.goThroughCardList(cards.length);
    final dialogBtnFinder = _assureDialogBtnExistence(true);

    await assistant.tapWidget(dialogBtnFinder);

    await screenTester.goToPreviousCard();

    _assureDialogBtnExistence(false);
    _assureFrontSideRendering(tester, packs, cards,
        expectedIndex: cards.length - 1);
  });

  testWidgets(
      'Updates a study date for each studied pack after finishing a study cycle',
      (tester) async {
    final packStorage = new PackStorageMock();

    final screenTester = new StudyScreenTester(new WidgetAssistant(tester));
    final packsToStudy = screenTester
        .takeEnoughCards(await _fetchNamedPacks(tester, packStorage));
    await _pumpScreen(tester, packStorage, packsToStudy);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packsToStudy, packStorage.wordStorage));

    await screenTester.goThroughCardList(cards.length);

    final updatedPacks = await _fetchNamedPacks(tester, packStorage);
    final packsToStudyIds = packsToStudy.map((p) => p.id).toSet();

    final now = DateTime.now();
    final studiedPacks = updatedPacks.where((p) =>
        packsToStudyIds.contains(p.id) &&
        p.studyDate!.difference(now).inSeconds < 1);
    expect(studiedPacks.length, packsToStudy.length);
  });

  testWidgets(
      'Increases study progress for a card after clicking the Learn button, updates it visually and moves next',
      (tester) async {
    final packStorage = new PackStorageMock();

    final assistant = new WidgetAssistant(tester);
    final packs = new StudyScreenTester(assistant)
        .takeEnoughCards(await _fetchNamedPacks(tester, packStorage));
    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));
    var cardToLearn = cards.first;

    if ([WordStudyStage.learned, WordStudyStage.familiar]
        .contains(cardToLearn.studyProgress))
      cardToLearn = (await packStorage.wordStorage
          .updateWordProgress(cardToLearn.id!, WordStudyStage.wellKnown))!;

    final curStudyProgress = cardToLearn.studyProgress;

    await _pumpScreen(tester, packStorage, packs);

    await assistant.tapWidget(AssuredFinder.findOne(
        label:
            Localizator.defaultLocalization.studyScreenLearningCardButtonLabel,
        type: ElevatedButton,
        shouldFind: true));

    _assureFrontSideRendering(tester, packs, cards, expectedIndex: 1);

    final curCardToLearn = await tester
        .runAsync(() => packStorage.wordStorage.find(cardToLearn.id));
    expect(curCardToLearn!.studyProgress - curStudyProgress, 25);

    await new StudyScreenTester(assistant).goToPreviousCard();
    _assureFrontSideRendering(tester, packs, cards, card: curCardToLearn);
  });

  testWidgets(
      'Shows the back side of a card when tapping it and the front side of the next one when navigating forward',
      (tester) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));

    final assistant = new WidgetAssistant(tester);
    await _reverseCardSide(assistant);

    _assureBackSideRendering(tester, packs, cards, isReversed: true);

    final screenTester = new StudyScreenTester(assistant);
    await _goToNextCard(screenTester,
        shouldSwipe:
            cardNavigationWay.currentValue! == _CardNavigationWay.bySwipe);

    _assureFrontSideRendering(tester, packs, cards, expectedIndex: 1);
  }, variant: cardNavigationWay);

  testWidgets(
      'Shows the back side of cards when navigating and the front one when clicking on them',
      (tester) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));

    final assistant = new WidgetAssistant(tester);
    await _pressButtonEndingWithText(
        assistant, CardSide.front.present(Localizator.defaultLocalization));

    _assureBackSideRendering(tester, packs, cards);

    final screenTester = new StudyScreenTester(assistant);
    await _goToNextCard(screenTester,
        shouldSwipe:
            cardNavigationWay.currentValue! == _CardNavigationWay.bySwipe);

    const nextIndex = 1;
    _assureBackSideRendering(tester, packs, cards, expectedIndex: nextIndex);

    await _reverseCardSide(assistant);
    _assureFrontSideRendering(tester, packs, cards,
        expectedIndex: nextIndex, isReversed: true);

    await screenTester.goToPreviousCard();
    _assureBackSideRendering(tester, packs, cards);
  }, variant: cardNavigationWay);

  testWidgets(
      'Shows a random side of cards when navigating and the opposite one when clicking on them',
      (tester) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));

    final assistant = new WidgetAssistant(tester);

    for (final sideMode in [CardSide.front, CardSide.back])
      await _pressButtonEndingWithText(
          assistant, sideMode.present(Localizator.defaultLocalization));

    int curIndex = 0;
    do {
      if (curIndex > 0)
        await _goToNextCard(new StudyScreenTester(assistant),
            shouldSwipe:
                cardNavigationWay.currentValue! == _CardNavigationWay.bySwipe);

      final cardText = _getShownCardText(tester);
      final curCard = cards[curIndex];

      final isFrontSide = curCard.text == cardText;
      if (isFrontSide)
        _assureFrontSideRendering(tester, packs, cards,
            card: curCard, expectedIndex: curIndex);
      else
        _assureBackSideRendering(tester, packs, cards,
            card: curCard, expectedIndex: curIndex);

      await _reverseCardSide(assistant);
      if (isFrontSide)
        _assureBackSideRendering(tester, packs, cards,
            card: curCard, expectedIndex: curIndex, isReversed: true);
      else
        _assureFrontSideRendering(tester, packs, cards,
            card: curCard, expectedIndex: curIndex, isReversed: true);
    } while (++curIndex < 2);
  }, variant: cardNavigationWay);

  testWidgets(
      'Reverses a card side from its front to its back and to its front again',
      (tester) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));

    final assistant = new WidgetAssistant(tester);
    await _reverseCardSide(assistant);

    _assureBackSideRendering(tester, packs, cards, isReversed: true);

    await _reverseCardSide(assistant);
    _assureFrontSideRendering(tester, packs, cards);
  });

  testWidgets(
      'Renders a dialog for editing a current card after clicking the Edit button',
      (tester) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    await _openEditorMode(tester);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));
    final cardToEdit = cards.first;

    final editorTester = new CardEditorTester(tester);
    editorTester.assureRenderingCardFields(cardToEdit);
    editorTester.assureRenderingPack(_findPack(packs, cardToEdit.packId));

    if (cardToEdit.studyProgress == WordStudyStage.unknown)
      CardEditorTester.findStudyProgressButton(shouldFind: false);
    else
      editorTester.assureNonZeroStudyProgress(cardToEdit.studyProgress);

    CardEditorTester.findSpeakerButton(shouldFind: true);
  });

  testWidgets(
      'Displays all named packs filtered by a language pair in the pack selector dialog',
      (tester) async {
    final packStorage = new PackStorageMock(singleLanguagePair: false);
    final langPairs = await packStorage.fetchLanguagePairs();

    final expectedLangPair = langPairs.first;
    await _pumpScreen(tester, packStorage, null, expectedLangPair);

    await _openEditorMode(tester);

    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(CardEditorTester.findPackButton());

    final namedPacks = await StorageFetcher.fetchNamedPacks(packStorage, langPair: expectedLangPair);
    final packNames = namedPacks.map((p) => p.name).toSet();
    SelectorDialogTester.assureRenderedOptions(tester, namedPacks, (finder, _) {
      final itemTitleFinder =
          find.descendant(of: finder, matching: find.byType(Text));
      final itemTitle = tester.widget<Text>(itemTitleFinder.first);
      expect(packNames.contains(itemTitle.data), true);
    }, ListTile);
  });

  testWidgets(
      'Cancels changes in the dialog for editing a card when clicking the Cancel button',
      (tester) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    await _openEditorMode(tester);

    final wordStorage = packStorage.wordStorage;
    final cards =
        _sortCards(await _fetchPackedCards(tester, packs, wordStorage));
    final cardToEdit = cards.first;

    final assistant = new WidgetAssistant(tester);
    final initialTranslation = cardToEdit.translation;
    final changedTranslation =
        await assistant.enterChangedText(initialTranslation!);

    await new CancellableDialogTester(tester).assureCancellingDialog();

    final storedCard = await wordStorage.find(cardToEdit.id);
    expect(storedCard!.translation, initialTranslation);

    _assureFrontSideRendering(tester, packs, cards, card: storedCard);

    await _reverseCardSide(assistant);
    _assureBackSideRendering(tester, packs, cards,
        card: storedCard, isReversed: true);

    AssuredFinder.findOne(label: changedTranslation, shouldFind: false);
  });

  testWidgets(
      'Saves changes after editing a card in the dialog and shows the changed card',
      (tester) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    await _openEditorMode(tester);

    final wordStorage = packStorage.wordStorage;
    final cards =
        _sortCards(await _fetchPackedCards(tester, packs, wordStorage));
    final cardToEdit = cards.first;

    final editorTester = new CardEditorTester(tester);

    final assistant = new WidgetAssistant(tester);
    final initialTranslation = cardToEdit.translation;
    final changedTranslation =
        await assistant.enterChangedText(initialTranslation!);

    final initialPack = _findPack(packs, cardToEdit.packId);
    final changedPack =
        packs.firstWhere((p) => !p.isNone && p.id != cardToEdit.packId);
    await editorTester.changePack(changedPack);

    await assistant.tapWidget(CardEditorTester.findSaveButton());

    final storedCard = await wordStorage.find(cardToEdit.id);
    expect(storedCard!.translation, changedTranslation);
    expect(storedCard.packId, changedPack.id);

    _assureFrontSideRendering(tester, packs, cards, card: storedCard);
    AssuredFinder.findOne(label: initialPack.name, shouldFind: false);

    await _reverseCardSide(assistant);
    _assureBackSideRendering(tester, packs, cards,
        card: storedCard, isReversed: true);
    AssuredFinder.findOne(label: initialTranslation, shouldFind: false);
  });
}

Future<List<StoredPack>> _pumpScreen(
    WidgetTester tester, PackStorageMock packStorage,
    [List<StoredPack>? packs, LanguagePair? langPair]) async {
  packs ??= await _fetchNamedPacks(tester, packStorage);

  await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
      noBar: true,
      childBuilder: (context) => new SettingsBlocProvider(
          child: new StudyScreen(packStorage.wordStorage,
              provider: new AssetDictionaryProvider(context),
              packs: packs ?? [],
              packStorage: packStorage,
              languagePair: langPair,
              defaultSpeaker: const SpeakerMock()))));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  return packs;
}

Future<List<StoredPack>> _fetchNamedPacks(
        WidgetTester tester, PackStorageMock packStorage) async =>
    (await tester.runAsync(() => StorageFetcher.fetchNamedPacks(packStorage)))!;

Future<List<StoredWord>> _fetchPackedCards(WidgetTester tester,
        List<StoredPack> packs, WordStorageMock wordStorage) async =>
    (await tester
        .runAsync(() => StorageFetcher.fetchPackedCards(packs, wordStorage)))!;

List<StoredWord> _sortCards(List<StoredWord> cards, [bool isBackward = false]) {
  if (isBackward) {
    const startIndex = 1;
    final cardsToSort = cards.sublist(startIndex, cards.length);
    cardsToSort.sort((a, b) => b.packId!.compareTo(a.packId!));
    cardsToSort.sort((a, b) => b.text.compareTo(a.text));

    cards.replaceRange(startIndex, cards.length, cardsToSort);
  } else {
    cards.sort((a, b) => a.packId!.compareTo(b.packId!));
    cards.sort((a, b) => a.text.compareTo(b.text));
  }

  return cards;
}

void _assureFrontSideRendering(
    WidgetTester tester, List<StoredPack> packs, List<StoredWord> cards,
    {int expectedIndex = 0, StoredWord? card, bool? isReversed}) {
  final expectedCard = card ?? cards.elementAt(expectedIndex);

  final cardFinder = _findCurrentCardSide(isReversed: isReversed);
  expect(
      find.descendant(of: cardFinder, matching: find.text(expectedCard.text)),
      findsOneWidget);

  final cardOtherTexts = tester
      .widgetList<Text>(
          find.descendant(of: cardFinder, matching: find.byType(Text)))
      .toList();
  cardOtherTexts.singleWhere(
      (w) => w.data!.contains(expectedCard.partOfSpeech!.valueList.first));
  expect(
      cardOtherTexts
          .where((w) => w.data!.contains(expectedCard.transcription))
          .length,
      1,
      reason:
          'There should be one widget with transcription: ${expectedCard.transcription}');

  expect(
      find.text(WordStudyStage.stringify(
          expectedCard.studyProgress, Localizator.defaultLocalization)),
      findsNWidgets(2));

  _assurePackNameRendering(packs, expectedCard.packId);

  _assureCardsNumberRendering(tester, cards.length, expectedIndex);
}

Finder _findCurrentCardSide({bool? isReversed}) {
  final cardFinder = find.byType(Card);
  return (isReversed ?? false) ? cardFinder.last : cardFinder.first;
}

void _assurePackNameRendering(List<StoredPack> packs, int? packId) {
  final expectedPack = _findPack(packs, packId);
  AssuredFinder.findOne(shouldFind: true, label: expectedPack.name);
}

StoredPack _findPack(List<StoredPack> packs, int? packId) =>
    packs.singleWhere((p) => p.id == packId);

void _assureCardsNumberRendering(
    WidgetTester tester, int cardsNumber, int curCardIndex) {
  tester
      .widgetList<Text>(find.descendant(
          of: find.byType(NavigationBar), matching: find.byType(Text)))
      .singleWhere(
          (t) => t.data!.contains('${curCardIndex + 1} of $cardsNumber'));
}

Future<void> _testChangingStudyModes(
    WidgetTester tester, List<PresentableEnum> modeValues) async {
  final assistant = new WidgetAssistant(tester);

  int i = 0;
  do {
    await _pressButtonEndingWithText(
        assistant, modeValues[i].present(Localizator.defaultLocalization));
  } while (++i < modeValues.length);
}

Future<void> _pressButtonEndingWithText(
        WidgetAssistant assistant, String text) =>
    assistant.pressWidgetDirectly(_findButtonEndingWithText(text));

Finder _findButtonEndingWithText(String text) => find.ancestor(
    of: find.byWidgetPredicate((w) => w is Text && w.data!.endsWith(text),
        skipOffstage: false),
    matching: find.byType(ElevatedButton, skipOffstage: false));

Future<void> _goToNextCard(StudyScreenTester tester,
    {required bool shouldSwipe}) async {
  await (shouldSwipe
      ? tester.goToNextCardBySwipe()
      : tester.goToNextCardByClick());
}

StoredWord _getShownCard(WidgetTester tester, List<StoredWord> cards) {
  final cardText = _getShownCardText(tester);
  return cards
      .singleWhere((c) => c.text == cardText || c.translation == cardText);
}

String? _getShownCardText(WidgetTester tester) {
  final cardTileFinder = find.descendant(
      of: _findCurrentCardSide(),
      matching: find.descendant(
          of: find.byType(ListTile), matching: find.byType(Text)));

  return tester.widget<Text>(cardTileFinder.first).data;
}

Finder _assureDialogBtnExistence(bool shouldFind) {
  final dialogBtnFinder = DialogTester.findConfirmationDialogBtn();
  expect(dialogBtnFinder, AssuredFinder.matchOne(shouldFind: shouldFind));

  return dialogBtnFinder;
}

void _assureBackSideRendering(
    WidgetTester tester, List<StoredPack> packs, List<StoredWord> cards,
    {int expectedIndex = 0, StoredWord? card, bool? isReversed}) {
  final expectedCard = card ?? cards.elementAt(expectedIndex);

  final cardFinder = _findCurrentCardSide(isReversed: isReversed);
  expect(
      find.descendant(
          of: cardFinder, matching: find.text(expectedCard.translation!)),
      findsOneWidget);

  expect(
      find.text(WordStudyStage.stringify(
          expectedCard.studyProgress, Localizator.defaultLocalization)),
      findsNWidgets(2));

  _assurePackNameRendering(packs, expectedCard.packId);

  _assureCardsNumberRendering(tester, cards.length, expectedIndex);
}

Future<void> _reverseCardSide(WidgetAssistant assistant) =>
    assistant.tapWidget(StudyScreenTester.findCardWidget(), atCenter: true);

Future<void> _openEditorMode(WidgetTester tester) =>
    new WidgetAssistant(tester).tapWidget(find.byIcon(Icons.edit));
