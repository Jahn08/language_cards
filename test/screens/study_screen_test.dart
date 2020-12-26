import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/enum.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/models/user_params.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/study_screen.dart';
import 'package:language_cards/src/widgets/navigation_bar.dart';
import '../mocks/pack_storage_mock.dart';
import '../mocks/root_widget_mock.dart';
import '../mocks/word_storage_mock.dart';
import '../utilities/assured_finder.dart';
import '../utilities/widget_assistant.dart';

void main() {

    testWidgets('Renders card data along with buttons for configuring the study mode', 
        (tester) async {
            final packStorage = new PackStorageMock();
            final packs = await _pumpScreen(tester, packStorage);
            
            expect(find.descendant(of: find.byType(RaisedButton, skipOffstage: false), 
                matching: find.byType(Text, skipOffstage: false)), findsNWidgets(4));

            final cards = _sortCards(
                await _fetchPackedCards(tester, packs, packStorage.wordStorage));
            _assureCardRendering(tester, packs, cards, expectedIndex: 0);
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
        (tester) async {
            final packStorage = new PackStorageMock();
            final packs = await _pumpScreen(tester, packStorage);

            final cards = _sortCards(
                await _fetchPackedCards(tester, packs, packStorage.wordStorage));

            final assistant = new WidgetAssistant(tester);
            final cardFinder = find.byType(Card);
            await assistant.swipeWidgetLeft(cardFinder);
            _assureCardRendering(tester, packs, cards, expectedIndex: 1);

            await assistant.swipeWidgetRight(cardFinder);
            _assureCardRendering(tester, packs, cards, expectedIndex: 0);
        });

    testWidgets('Renders next/previous card data when swiping left/right with the backward sorting', 
        (tester) async {
            final packStorage = new PackStorageMock();
            final packs = await _pumpScreen(tester, packStorage);

            final cards = _sortCards(
                await _fetchPackedCards(tester, packs, packStorage.wordStorage), true);

            final assistant = new WidgetAssistant(tester);
            await _pressButtonContainingText(assistant, 
                Enum.stringifyValue(StudyDirection.forward));

            final cardFinder = find.byType(Card);
            await assistant.swipeWidgetLeft(cardFinder);
            _assureCardRendering(tester, packs, cards, expectedIndex: 1);

            await assistant.swipeWidgetRight(cardFinder);
            _assureCardRendering(tester, packs, cards, expectedIndex: 0);
        });

    testWidgets('Renders next/previous card data when swiping left/right with the random sorting', 
        (tester) async {
            final packStorage = new PackStorageMock();
            final packs = await _pumpScreen(tester, packStorage);

            final cards = await _fetchPackedCards(tester, packs, packStorage.wordStorage);

            final assistant = new WidgetAssistant(tester);

            for (final sortMode in [StudyDirection.forward, StudyDirection.backward])
                await _pressButtonContainingText(assistant, Enum.stringifyValue(sortMode));

            final firstCard = _getShownCard(tester, cards);

            final cardFinder = find.byType(Card);
            await assistant.swipeWidgetLeft(cardFinder);
            
            final nextCard = _getShownCard(tester, cards);
            _assureCardRendering(tester, packs, cards, card: nextCard, expectedIndex: 1);

            await assistant.swipeWidgetRight(cardFinder);

            _assureCardRendering(tester, packs, cards, card: firstCard, expectedIndex: 0);
        });
}

Future<List<StoredPack>> _pumpScreen(WidgetTester tester, PackStorageMock packStorage) async {
    final packs = (await tester.runAsync(() async => await packStorage.fetch()))
        .where((p) => !p.isNone).toList();
    await tester.pumpWidget(RootWidgetMock.buildAsAppHome(noBar: true,
        child: new StudyScreen(packStorage.wordStorage, packs: packs)));
    await tester.pump(new Duration(milliseconds: 500));

    return packs;
}

Future<List<StoredWord>> _fetchPackedCards(WidgetTester tester, List<StoredPack> packs, 
    WordStorageMock wordStorage) async {
    
    return await tester.runAsync(() async => 
        await wordStorage.fetchFiltered(parentIds: packs.map((p) => p.id).toList()));
}

List<StoredWord> _sortCards(List<StoredWord> cards, [bool isBackward = false]) {
    if (isBackward) {
        cards.sort((a, b) => b.packId.compareTo(a.packId));
        cards.sort((a, b) => b.text.compareTo(a.text));
    }
    else {
        cards.sort((a, b) => a.packId.compareTo(b.packId));
        cards.sort((a, b) => a.text.compareTo(b.text));
    }   
    
    return cards;
}

void _assureCardRendering(WidgetTester tester, List<StoredPack> packs,
    List<StoredWord> cards, { int expectedIndex, StoredWord card }) {
    expectedIndex = expectedIndex ?? 0;
    final expectedCard = card ?? cards.elementAt(expectedIndex);

    expect(find.descendant(of: find.byType(Card), 
        matching: find.text(expectedCard.text)), findsOneWidget);

    final cardOtherTexts = tester.widgetList<Text>(
        find.descendant(of: find.byType(Card), matching: find.byType(Text))).toList();
    cardOtherTexts.singleWhere((w) => w.data.contains(expectedCard.partOfSpeech));
    cardOtherTexts.singleWhere((w) => w.data.contains(expectedCard.transcription));
    
    AssuredFinder.findOne(shouldFind: true, 
        label: WordStudyStage.stringify(expectedCard.studyProgress));

    final expectedPack = packs.singleWhere((p) => p.id == expectedCard.packId);
    AssuredFinder.findOne(shouldFind: true, label: expectedPack.name);

    tester.widgetList<Text>(find.descendant(of: find.byType(NavigationBar),
        matching: find.byType(Text)))
        .singleWhere((t) => t.data.contains('${expectedIndex + 1} of ${cards.length}'));
}

Future<void> _testChangingStudyModes(WidgetTester tester, List<dynamic> modeValues) async {
    final assistant = new WidgetAssistant(tester);

    int i = 0;
    do {
        await _pressButtonContainingText(assistant, Enum.stringifyValue(modeValues[i]));
    } while (++i < modeValues.length);
}

Future<void> _pressButtonContainingText(WidgetAssistant assistant, String text) async {
    final btnFinder = find.ancestor(
        of: find.byWidgetPredicate((w) => w is Text && 
            w.data.contains(text), skipOffstage: false),
        matching: find.byType(RaisedButton, skipOffstage: false));

    await assistant.pressButtonDirectly(btnFinder);
}

StoredWord _getShownCard(WidgetTester tester, List<StoredWord> cards) {
    final cardFinder = find.byType(Card);
    final cardTileFinder = find.descendant(of: cardFinder, 
        matching: find.byType(ListTile));

    final cardText = (tester.widget<ListTile>(cardTileFinder).title as Text).data;
    return cards.singleWhere((c) => c.text == cardText);
}
