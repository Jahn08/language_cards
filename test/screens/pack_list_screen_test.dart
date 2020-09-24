import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/router.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/screens/card_list_screen.dart';
import 'package:language_cards/src/screens/pack_list_screen.dart';
import '../testers/list_screen_tester.dart';
import '../utilities/mock_pack_storage.dart';
import '../utilities/mock_word_storage.dart';
import '../utilities/test_root_widget.dart';
import '../utilities/widget_assistant.dart';

void main() {
    new ListScreenTester('Pack', _buildPackListScreen).testEditorMode();

    testWidgets("Doesn't update a number of cards for a pack without changes in it", (tester) async {
        final storage = await _pumpScreenWithRouting(tester);

        final packWithCards = await _getFirstPackWithCards(storage, tester);
        final expectedNumberOfCards = packWithCards.cardsNumber;
        
        final assistant = new WidgetAssistant(tester);
        await _goToCardList(assistant, packWithCards.name);

        expect(find.byType(Dismissible), findsNWidgets(expectedNumberOfCards));

        await _goBackToPackList(assistant);

        await _assertPackCardNumber(tester, storage, packWithCards, expectedNumberOfCards);
    });

    testWidgets("Decreases a number of cards for a pack after deleting one", (tester) async {
        final storage = await _pumpScreenWithRouting(tester);

        final packWithCards = await _getFirstPackWithCards(storage, tester);
        final expectedNumberOfCards = packWithCards.cardsNumber - 1;
        
        final assistant = new WidgetAssistant(tester);
        await _goToCardList(assistant, packWithCards.name);

        tester.widget<Dismissible>(find.byType(Dismissible).first)
            .onDismissed.call(DismissDirection.endToStart);
        
        await _goBackToPackList(assistant);

        await _assertPackCardNumber(tester, storage, packWithCards, expectedNumberOfCards);
    });

    testWidgets("Increases a number of cards for a pack after adding one", (tester) async {
        final storage = await _pumpScreenWithRouting(tester, cardWasAdded: true);

        final packWithCards = await _getFirstPackWithCards(storage, tester);
        final expectedNumberOfCards = packWithCards.cardsNumber + 1;

        final assistant = new WidgetAssistant(tester);
        await _goToCardList(assistant, packWithCards.name);

        await tester.runAsync(() async {
            final randomWord = MockWordStorage.generateWord(packId: packWithCards.id);
            final saveOutcome = await storage.wordStorage.save(randomWord);
            expect(saveOutcome, true);
        });

        await _goBackToPackList(assistant);

        await _assertPackCardNumber(tester, storage, packWithCards, expectedNumberOfCards);
    });
}

PackListScreen _buildPackListScreen([MockPackStorage storage]) => 
    new PackListScreen(storage ?? new MockPackStorage());
    
Future<MockPackStorage> _pumpScreenWithRouting(WidgetTester tester, { bool cardWasAdded }) async {
    final storage = new MockPackStorage();
    await tester.pumpWidget(new MaterialApp(
        initialRoute: Router.initialRouteName,
        onGenerateRoute: (settings) {
            final route = Router.getRoute(settings);

            if (route is CardListRoute)
                return new MaterialPageRoute(
                    settings: settings,
                    builder: (context) => new TestRootWidget(
                        child: new CardListScreen(storage.wordStorage, pack: route.params.pack, 
                            cardWasAdded: cardWasAdded))
                );

            return new MaterialPageRoute(
                settings: settings,
                builder: (context) => new TestRootWidget(child: _buildPackListScreen(storage))
            );
        }));

    await tester.pumpAndSettle(new Duration(milliseconds: 900));

    return storage;
}

Future<StoredPack> _getFirstPackWithCards(MockPackStorage storage, WidgetTester tester) async => 
    await tester.runAsync<StoredPack>(
        () async => (await storage.fetch()).firstWhere((p) => p.cardsNumber > 0));

Future<void> _goToCardList(WidgetAssistant assistant, String cardName) async {
    final tileWithCardsFinder = find.ancestor(of: find.text(cardName), 
        matching: find.byType(ListTile));
    expect(tileWithCardsFinder, findsOneWidget);
    await assistant.tapWidget(tileWithCardsFinder);
}

Future<void> _goBackToPackList(WidgetAssistant assistant, [Duration duration]) async {
    final backBtnFinders = find.byType(BackButton);
    assistant.tester.widget<BackButton>(backBtnFinders.first).onPressed.call();

    await (duration == null ? assistant.tester.pumpAndSettle() : 
        assistant.tester.pumpAndSettle(duration));
}

Future<void> _assertPackCardNumber(WidgetTester tester, MockPackStorage storage, 
    StoredPack pack, int expectedNumber) async {
    final tileWithCardsFinder = find.ancestor(of: find.text(pack.name), 
        matching: find.byType(ListTile));
    expect(tileWithCardsFinder, findsOneWidget);
    
    expect(find.descendant(of: tileWithCardsFinder, 
        matching: find.text(expectedNumber.toString())), findsOneWidget);

    await tester.runAsync(() async {
        final actualPackWithCards = await storage.find(pack.id);
        expect(actualPackWithCards?.cardsNumber, expectedNumber);
    });
}
