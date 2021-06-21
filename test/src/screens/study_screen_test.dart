import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/widget_assistant.dart';

void main() {

	setUp(() => PreferencesTester.resetSharedPreferences());

    testWidgets('Renders card data along with buttons for configuring the study mode', 
        (tester) async {
            final packStorage = new PackStorageMock();
            final packs = await _pumpScreen(tester, packStorage);
			
            expect(find.descendant(of: find.byType(ElevatedButton, skipOffstage: false), 
                matching: find.byType(Text, skipOffstage: false)), findsNWidgets(4));

            final cards = _sortCards(
                await _fetchPackedCards(tester, packs, packStorage.wordStorage));
            _assureFrontSideRendering(tester, packs, cards, expectedIndex: 0);
        });

	testWidgets('Renders the study mode buttons in accordance with user preferences', (tester) async {
		final expectedParams = await PreferencesTester.saveNonDefaultUserParams();

		await _pumpScreen(tester, new PackStorageMock());
		
		final locale = Localizator.defaultLocalization;
		final studyParams = expectedParams.studyParams;
		expect(_findButtonEndingWithText(studyParams.direction.present(locale)), findsOneWidget);
		expect(_findButtonEndingWithText(studyParams.cardSide.present(locale)), findsOneWidget);
	});

    testWidgets('Renders a name for a chosen sorting mode when clicking on the button', 
        (tester) async {
            await _pumpScreen(tester, new PackStorageMock());

            await _testChangingStudyModes(tester, 
                StudyDirection.values.toList()..add(StudyDirection.forward));
        });

    testWidgets('Renders a name for a chosen card side mode when clicking on the button', 
        (tester) async {
            await _pumpScreen(tester, new PackStorageMock());

            await _testChangingStudyModes(tester, 
                CardSide.values.toList()..add(CardSide.front));
        });

    testWidgets('Renders next/previous card data when swiping left/right with the forward sorting', 
        (tester) async => await _testForwardSorting(tester, shouldSwipe: true));

    testWidgets('Renders next/previous card data when swiping left/right with the backward sorting', 
        (tester) async => await _testBackwardSorting(tester, shouldSwipe: true));

    testWidgets('Renders next/previous card data when swiping left/right with the random sorting', 
        (tester) async => await _testRandomSorting(tester, shouldSwipe: true));

    testWidgets('Renders next/previous card data when clicking the next button/swiping right with the forward sorting', 
        (tester) async => await _testForwardSorting(tester, shouldSwipe: false));

    testWidgets('Renders next/previous card data when clicking the next button/swiping right with the backward sorting', 
        (tester) async => await _testBackwardSorting(tester, shouldSwipe: false));

    testWidgets('Renders next/previous card data when clicking the next button/swiping right with the random sorting', 
        (tester) async => await _testRandomSorting(tester, shouldSwipe: false));

    testWidgets('Shows a dialog after finishing a study cycle, then closes it and starts afresh', 
        (tester) async {
            final packStorage = new PackStorageMock();

            final packs = _takeEnoughCards((await _fetchNamedPacks(tester, packStorage)));
            await _pumpScreen(tester, packStorage, packs);

            final cards = _sortCards(
                await _fetchPackedCards(tester, packs, packStorage.wordStorage));

            await _goThroughCardList(tester, cards.length);

            final dialogBtnFinder = _assureDialogBtnExistence(true);
            await new WidgetAssistant(tester).tapWidget(dialogBtnFinder);

            _assureFrontSideRendering(tester, packs, cards, expectedIndex: 0);

            _assureDialogBtnExistence(false);
        });

    testWidgets('Shows no dialog after going backward from the first card to the last one', 
        (tester) async {
            final packStorage = new PackStorageMock();

            final packs = _takeEnoughCards((await _fetchNamedPacks(tester, packStorage)));
            await _pumpScreen(tester, packStorage, packs);

            final cards = _sortCards(
                await _fetchPackedCards(tester, packs, packStorage.wordStorage));
            await _goThroughCardList(tester, cards.length);
            final dialogBtnFinder = _assureDialogBtnExistence(true);

            final assistant = new WidgetAssistant(tester);
            await assistant.tapWidget(dialogBtnFinder);

            await assistant.swipeWidgetRight(_findCardWidget());

            _assureDialogBtnExistence(false);
            _assureFrontSideRendering(tester, packs, cards, expectedIndex: cards.length - 1);
        });

    testWidgets('Increases study progress for a card after clicking the Learn button and moves next', 
      (tester) async {
          	final packStorage = new PackStorageMock();

			final packs = _takeEnoughCards((await _fetchNamedPacks(tester, packStorage)));
			final cards = _sortCards(
				await _fetchPackedCards(tester, packs, packStorage.wordStorage));
			var cardToLearn = cards.first;

			if (cardToLearn.studyProgress == WordStudyStage.learned)
				cardToLearn = await packStorage.wordStorage.updateWordProgress(cardToLearn.id, 
					WordStudyStage.familiar);

			final curStudyProgress = cardToLearn.studyProgress;

			await _pumpScreen(tester, packStorage, packs);

			final learnBtnFinder = AssuredFinder.findOne(
				label: Localizator.defaultLocalization.studyScreenLearningCardButtonLabel,
				 type: ElevatedButton, 
				shouldFind: true
			);
			await new WidgetAssistant(tester).tapWidget(learnBtnFinder);

			_assureFrontSideRendering(tester, packs, cards, expectedIndex: 1);

			cardToLearn = await tester.runAsync(() => packStorage.wordStorage.find(cardToLearn.id));
			expect(cardToLearn.studyProgress - curStudyProgress, 25);
      });

    testWidgets('Shows the back side of a card when tapping it and the front side of the next one when swiping left', 
        (tester) async => _testReversingFrontCardSide(tester, shouldSwipe: true));

    testWidgets('Shows the back side of a card when tapping it and the front side of the next one when clicking the next button', 
        (tester) async => _testReversingFrontCardSide(tester, shouldSwipe: false));

    testWidgets('Shows the back side of cards when swiping left/right and the front one when clicking on them',
        (tester) async => _testReversingBackCardSide(tester, shouldSwipe: true));

    testWidgets('Shows the back side of cards when clicking the next button/swiping right and the front one when clicking on them',
        (tester) async => _testReversingBackCardSide(tester, shouldSwipe: false));

    testWidgets('Shows a random side of cards when swiping left and the opposite one when clicking on them',
        (tester) async => _testReversingRandomCardSide(tester, shouldSwipe: true));

    testWidgets('Shows a random side of cards when clicking the next button and the opposite one when clicking on them',
        (tester) async => _testReversingRandomCardSide(tester, shouldSwipe: false));

    testWidgets('Reverses a card side from its front to its back and to its front again',
        (tester) async {
            final packStorage = new PackStorageMock();
            final packs = await _pumpScreen(tester, packStorage);

            final cards = _sortCards(
                await _fetchPackedCards(tester, packs, packStorage.wordStorage));
            
            final assistant = new WidgetAssistant(tester);
            await _reverseCardSide(assistant);
            
            const firstIndex = 0;
            _assureBackSideRendering(tester, packs, cards, expectedIndex: firstIndex, 
                isReversed: true);
            
            await _reverseCardSide(assistant);
            _assureFrontSideRendering(tester, packs, cards, expectedIndex: firstIndex);
        });

	testWidgets('Renders a dialog for editing a current card after clicking the Edit button',
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
	
	testWidgets('Cancels changes in the dialog for editing a card when clicking the Cancel button',
        (tester) async { 
			final packStorage = new PackStorageMock();
			final packs = await _pumpScreen(tester, packStorage);

			await _openEditorMode(tester);

			final wordStorage = packStorage.wordStorage;
            final cards = _sortCards(await _fetchPackedCards(tester, packs, wordStorage));
			final cardToEdit = cards.first;
			
			final initialTranslation = cardToEdit.translation;
			final changedTranslation = 
				await new CardEditorTester(tester).enterChangedText(initialTranslation);

			await new CancellableDialogTester(tester).assureCancellingDialog();
			
            final storedCard = await wordStorage.find(cardToEdit.id);
            expect(storedCard.translation, initialTranslation);

			final expectedIndex = 0;
			_assureFrontSideRendering(tester, packs, cards, card: storedCard, 
				expectedIndex: expectedIndex);

            await _reverseCardSide(new WidgetAssistant(tester));
            _assureBackSideRendering(tester, packs, cards, card: storedCard, 
				expectedIndex: expectedIndex, isReversed: true);

			AssuredFinder.findOne(label: changedTranslation, shouldFind: false);
		});

	testWidgets('Saves changes after editing a card in the dialog and shows the changed card',
        (tester) async { 
			final packStorage = new PackStorageMock();
			final packs = await _pumpScreen(tester, packStorage);

			await _openEditorMode(tester);

			final wordStorage = packStorage.wordStorage;
            final cards = _sortCards(await _fetchPackedCards(tester, packs, wordStorage));
			final cardToEdit = cards.first;
			
			final editorTester = new CardEditorTester(tester);
			
			final initialTranslation = cardToEdit.translation;
			final changedTranslation = await editorTester.enterChangedText(initialTranslation);
			
			final initialPack = _findPack(packs, cardToEdit.packId);
			final changedPack = packs.firstWhere((p) => !p.isNone && p.id != cardToEdit.packId);
			await editorTester.changePack(changedPack);

			await new WidgetAssistant(tester).tapWidget(CardEditorTester.findSaveButton());
			
			final storedCard = await wordStorage.find(cardToEdit.id);
            expect(storedCard.translation, changedTranslation);
            expect(storedCard.packId, changedPack.id);

			final expectedIndex = 0;
			_assureFrontSideRendering(tester, packs, cards, card: storedCard, 
				expectedIndex: expectedIndex);
			AssuredFinder.findOne(label: initialPack.name, shouldFind: false);

            await _reverseCardSide(new WidgetAssistant(tester));
            _assureBackSideRendering(tester, packs, cards, card: storedCard, 
				expectedIndex: expectedIndex, isReversed: true);
			AssuredFinder.findOne(label: initialTranslation, shouldFind: false);
		});
}

Future<List<StoredPack>> _pumpScreen(WidgetTester tester, PackStorageMock packStorage,
    [List<StoredPack> packs]) async {
    if (packs == null)
        packs = await _fetchNamedPacks(tester, packStorage);

    await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
		noBar: true,
        childBuilder: (context) => new SettingsBlocProvider(
			child: new StudyScreen(packStorage.wordStorage, 
				provider: new AssetDictionaryProvider(context),
				packs: packs, packStorage: packStorage, 
				defaultSpeaker: new SpeakerMock())
		)
	));
    await tester.pump();
    await tester.pump(new Duration(milliseconds: 500));

    return packs;
}

Future<List<StoredPack>> _fetchNamedPacks(WidgetTester tester, PackStorageMock packStorage) async =>
    (await tester.runAsync(() async => await packStorage.fetch()))
        .where((p) => !p.isNone).toList();

Future<List<StoredWord>> _fetchPackedCards(WidgetTester tester, List<StoredPack> packs, 
    WordStorageMock wordStorage) async {
    
    return await tester.runAsync(() async => 
        await wordStorage.fetchFiltered(parentIds: packs.map((p) => p.id).toList()));
}

List<StoredWord> _sortCards(List<StoredWord> cards, [bool isBackward = false]) {
    if (isBackward) {
        final startIndex = 1;
        final cardsToSort = cards.sublist(startIndex, cards.length);
        cardsToSort.sort((a, b) => b.packId.compareTo(a.packId));
        cardsToSort.sort((a, b) => b.text.compareTo(a.text));

        cards.replaceRange(startIndex, cards.length, cardsToSort);
    }
    else {
        cards.sort((a, b) => a.packId.compareTo(b.packId));
        cards.sort((a, b) => a.text.compareTo(b.text));
    }   
    
    return cards;
}

void _assureFrontSideRendering(WidgetTester tester, List<StoredPack> packs,
    List<StoredWord> cards, { int expectedIndex, StoredWord card, bool isReversed }) {
    expectedIndex = expectedIndex ?? 0;
    final expectedCard = card ?? cards.elementAt(expectedIndex);

    final cardFinder = _findCurrentCardSide(isReversed: isReversed);
    expect(find.descendant(of: cardFinder, 
        matching: find.text(expectedCard.text)), findsOneWidget);

    final cardOtherTexts = tester.widgetList<Text>(
        find.descendant(of: cardFinder, matching: find.byType(Text))).toList();
    cardOtherTexts.singleWhere((w) => w.data.contains(expectedCard.partOfSpeech.valueList.first));
    expect(cardOtherTexts.where((w) => w.data.contains(expectedCard.transcription)).length, 1, 
		reason: 'There should be one widget with transcription: ${expectedCard.transcription}');
    
    expect(find.text(WordStudyStage.stringify(expectedCard.studyProgress, 
		Localizator.defaultLocalization)), findsNWidgets(2));

    _assurePackNameRendering(packs, expectedCard.packId);

    _assureCardsNumberRendering(tester, cards.length, expectedIndex);
}

Finder _findCurrentCardSide({ bool isReversed }) {
    final cardFinder = find.byType(Card);
    return (isReversed ?? false) ? cardFinder.last: cardFinder.first;
}

void _assurePackNameRendering(List<StoredPack> packs, int packId) {
    final expectedPack = _findPack(packs, packId);
    AssuredFinder.findOne(shouldFind: true, label: expectedPack.name);
}

StoredPack _findPack(List<StoredPack> packs, int packId) => 
	packs.singleWhere((p) => p.id == packId);

void _assureCardsNumberRendering(WidgetTester tester, int cardsNumber, int curCardIndex) {
    tester.widgetList<Text>(find.descendant(of: find.byType(NavigationBar),
        matching: find.byType(Text)))
        .singleWhere((t) => t.data.contains('${curCardIndex + 1} of $cardsNumber'));
}

Future<void> _testChangingStudyModes(WidgetTester tester, List<PresentableEnum> modeValues) async {
    final assistant = new WidgetAssistant(tester);
	
    int i = 0;
    do {
        await _pressButtonEndingWithText(assistant, 
			modeValues[i].present(Localizator.defaultLocalization));
    } while (++i < modeValues.length);
}

Finder _findCardWidget() => find.byType(PageView);

Future<void> _pressButtonEndingWithText(WidgetAssistant assistant, String text) => 
	assistant.pressButtonDirectly(_findButtonEndingWithText(text));

Finder _findButtonEndingWithText(String text) => 
	find.ancestor(of: find.byWidgetPredicate((w) => w is Text && 
		w.data.endsWith(text), skipOffstage: false),
        matching: find.byType(ElevatedButton, skipOffstage: false));

Future<void> _testForwardSorting(WidgetTester tester, { bool shouldSwipe }) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));

    final assistant = new WidgetAssistant(tester);
    await _goToNextCard(assistant, shouldSwipe);
    
    _assureFrontSideRendering(tester, packs, cards, expectedIndex: 1);

    await assistant.swipeWidgetRight(_findCardWidget());
    _assureFrontSideRendering(tester, packs, cards, expectedIndex: 0);
}

Future<void> _testBackwardSorting(WidgetTester tester, { bool shouldSwipe }) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage), true);

    final assistant = new WidgetAssistant(tester);
    await _pressButtonEndingWithText(assistant, 
        StudyDirection.forward.present(Localizator.defaultLocalization));

    await _goToNextCard(assistant, shouldSwipe);
    _assureFrontSideRendering(tester, packs, cards, expectedIndex: 1);

    await assistant.swipeWidgetRight(_findCardWidget());
    _assureFrontSideRendering(tester, packs, cards, expectedIndex: 0);
}

Future<void> _testRandomSorting(WidgetTester tester, { bool shouldSwipe }) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = await _fetchPackedCards(tester, packs, packStorage.wordStorage);

    final assistant = new WidgetAssistant(tester);

    for (final sortMode in [StudyDirection.forward, StudyDirection.backward])
        await _pressButtonEndingWithText(assistant, 
			sortMode.present(Localizator.defaultLocalization));

    final firstCard = _getShownCard(tester, cards);

    await _goToNextCard(assistant, shouldSwipe);
    
    final nextCard = _getShownCard(tester, cards);
    _assureFrontSideRendering(tester, packs, cards, card: nextCard, expectedIndex: 1);

    await assistant.swipeWidgetRight(_findCardWidget());

    _assureFrontSideRendering(tester, packs, cards, card: firstCard, expectedIndex: 0);
}

StoredWord _getShownCard(WidgetTester tester, List<StoredWord> cards) {
    final cardText = _getShownCardText(tester);
    return cards.singleWhere((c) => c.text == cardText || c.translation == cardText);
}

String _getShownCardText(WidgetTester tester) {
    final cardTileFinder = find.descendant(of: _findCurrentCardSide(), 
        matching: find.byType(ListTile));

    return (tester.widget<ListTile>(cardTileFinder).title as Text).data;
}

Finder _assureDialogBtnExistence(bool shouldFind) {
	final dialogBtnFinder = DialogTester.findConfirmationDialogBtn();
	expect(dialogBtnFinder, AssuredFinder.matchOne(shouldFind: shouldFind)); 

	return dialogBtnFinder;
}

List<StoredPack> _takeEnoughCards(List<StoredPack> packs) {
    int cardsNumber = 0;
    return packs.takeWhile((p) {
        if (cardsNumber > 3)
            return false;

        cardsNumber += p.cardsNumber;
        return true;
    }).toList();
}

Future<void> _goToNextCard(WidgetAssistant assistant, bool bySwiping) async {
    if (bySwiping)
        await assistant.swipeWidgetLeft(_findCardWidget());
    else
        await assistant.tapWidget(find.widgetWithText(ElevatedButton, 'Next'));
}

void _assureBackSideRendering(WidgetTester tester, List<StoredPack> packs,
    List<StoredWord> cards, { int expectedIndex, StoredWord card, bool isReversed }) {
    expectedIndex = expectedIndex ?? 0;
    final expectedCard = card ?? cards.elementAt(expectedIndex);

    final cardFinder = _findCurrentCardSide(isReversed: isReversed);
    expect(find.descendant(of: cardFinder, 
        matching: find.text(expectedCard.translation)), findsOneWidget);

    expect(find.text(
		WordStudyStage.stringify(expectedCard.studyProgress, Localizator.defaultLocalization)), 
		findsNWidgets(2));

    _assurePackNameRendering(packs, expectedCard.packId);

    _assureCardsNumberRendering(tester, cards.length, expectedIndex);
}

Future<void> _testReversingFrontCardSide(WidgetTester tester, { bool shouldSwipe }) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));
    
    final assistant = new WidgetAssistant(tester);
    await _reverseCardSide(assistant);
    
    _assureBackSideRendering(tester, packs, cards, expectedIndex: 0, isReversed: true);

    await _goToNextCard(assistant, shouldSwipe);
    _assureFrontSideRendering(tester, packs, cards, expectedIndex: 1);
}

Future<void> _reverseCardSide(WidgetAssistant assistant) async => 
    await assistant.tapWidget(_findCardWidget());

Future<void> _testReversingBackCardSide(WidgetTester tester, { bool shouldSwipe }) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));

    final assistant = new WidgetAssistant(tester);
    await _pressButtonEndingWithText(assistant, 
		CardSide.front.present(Localizator.defaultLocalization));
	
    const firstIndex = 0;
    _assureBackSideRendering(tester, packs, cards, expectedIndex: firstIndex);
    
    await _goToNextCard(assistant, shouldSwipe);

    const nextIndex = 1;
    _assureBackSideRendering(tester, packs, cards, expectedIndex: nextIndex);

    await _reverseCardSide(assistant);
    _assureFrontSideRendering(tester, packs, cards, expectedIndex: nextIndex, isReversed: true);

    await assistant.swipeWidgetRight(_findCardWidget());
    _assureBackSideRendering(tester, packs, cards, expectedIndex: firstIndex);
}

Future<void> _testReversingRandomCardSide(WidgetTester tester, { bool shouldSwipe }) async {
    final packStorage = new PackStorageMock();
    final packs = await _pumpScreen(tester, packStorage);

    final cards = _sortCards(
        await _fetchPackedCards(tester, packs, packStorage.wordStorage));

    final assistant = new WidgetAssistant(tester);

    for (final sideMode in [CardSide.front, CardSide.back])
        await _pressButtonEndingWithText(assistant, 
			sideMode.present(Localizator.defaultLocalization));

    int curIndex = 0;
    do {
        if (curIndex > 0)
            await _goToNextCard(assistant, shouldSwipe);

        final cardText = _getShownCardText(tester);
        final curCard = cards[curIndex];

        final isFrontSide = curCard.text == cardText;
        if (isFrontSide)
            _assureFrontSideRendering(tester, packs, cards, card: curCard, 
                expectedIndex: curIndex);
        else
            _assureBackSideRendering(tester, packs, cards, card: curCard, 
                expectedIndex: curIndex);

        await _reverseCardSide(assistant);
        if (isFrontSide)
            _assureBackSideRendering(tester, packs, cards, card: curCard, 
                expectedIndex: curIndex, isReversed: true);
        else
            _assureFrontSideRendering(tester, packs, cards, card: curCard, 
                expectedIndex: curIndex, isReversed: true);

    } while (++curIndex < 2);
}

Future<void> _goThroughCardList(WidgetTester tester, int listLength) async {
	final assistant = new WidgetAssistant(tester);
	
	int index = 0;
	do {
		await _goToNextCard(assistant, true);
	} while (++index < listLength);
}

Future<void> _openEditorMode(WidgetTester tester) => 
	new WidgetAssistant(tester).tapWidget(find.byIcon(Icons.edit));
