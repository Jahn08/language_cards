import 'package:flutter/material.dart' hide Router;
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/router.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/screens/card_list_screen.dart';
import 'package:language_cards/src/screens/main_screen.dart';
import 'package:language_cards/src/screens/pack_screen.dart';
import 'package:language_cards/src/screens/pack_list_screen.dart';
import 'package:language_cards/src/widgets/card_number_indicator.dart';
import '../mocks/pack_storage_mock.dart';
import '../mocks/root_widget_mock.dart';
import '../mocks/word_storage_mock.dart';
import '../testers/list_screen_tester.dart';
import '../utilities/widget_assistant.dart';

void main() {
    final screenTester = new ListScreenTester('Pack', () => _buildPackListScreen());
    screenTester.testEditorMode();
    screenTester.testSearcherMode(PackStorageMock.generatePack);

    testWidgets("Doesn't update a number of cards for a pack without changes in it", (tester) async {
        final storage = await _pumpScreenWithRouting(tester);

        final packWithCards = await _getFirstPackWithCards(storage, tester);
        await _testShowingCardsWithoutChanging(tester, storage, packWithCards);
    });

    testWidgets("Decreases a number of cards for a pack after deleting one", (tester) async {
        final storage = await _pumpScreenWithRouting(tester);

        final packWithCards = await _getFirstPackWithCards(storage, tester);
        await _testDecreasingNumberOfCards(tester, storage, packWithCards);
    });

    testWidgets("Increases a number of cards for a pack after adding one", (tester) async {
        final storage = await _pumpScreenWithRouting(tester, cardWasAdded: true);

        final packWithCards = await _getFirstPackWithCards(storage, tester);
        await _testIncreasingNumberOfCards(tester, storage, packWithCards);
    });

    testWidgets("Renders an unremovable link for a list of cards without a pack", (tester) async {
        await screenTester.pumpScreen(tester);
        _findPackTileByName(StoredPack.noneName);

        await screenTester.activateEditorMode(new WidgetAssistant(tester));
        _findPackTileByName(StoredPack.noneName);
    });

    testWidgets("Doesn't update a number of cards for the none pack without changes in it", (tester) async {
        final storage = await _pumpScreenWithRouting(tester);

        final nonePack = await _getNonePack(storage, tester);
        await _testShowingCardsWithoutChanging(tester, storage, nonePack);
    });

    testWidgets("Decreases a number of cards for the none pack after deleting one", (tester) async {
        final storage = await _pumpScreenWithRouting(tester);

        final nonePack = await _getNonePack(storage, tester);
        await _testDecreasingNumberOfCards(tester, storage, nonePack);
    });

    testWidgets("Increases a number of cards for the none pack after adding one", (tester) async {
        final storage = await _pumpScreenWithRouting(tester, cardWasAdded: true);

        final nonePack = await _getNonePack(storage, tester);
        await _testIncreasingNumberOfCards(tester, storage, nonePack);
    });
}

PackListScreen _buildPackListScreen([PackStorageMock storage]) => 
    new PackListScreen(storage ?? new PackStorageMock());
    
Future<PackStorageMock> _pumpScreenWithRouting(WidgetTester tester, { bool cardWasAdded }) async {
    final storage = new PackStorageMock();
    await tester.pumpWidget(new MaterialApp(
        initialRoute: Router.initialRouteName,
        onGenerateRoute: (settings) {
            final route = Router.getRoute(settings);

            if (route == null)
                return new MaterialPageRoute(
                    settings: settings,
                    builder: (context) => new RootWidgetMock(child: new MainScreen())
                );
            if (route is CardListRoute)
                return new MaterialPageRoute(
                    settings: settings,
                    builder: (context) => new RootWidgetMock(
                        child: new CardListScreen(storage.wordStorage, pack: route.params.pack, 
                            cardWasAdded: cardWasAdded))
                );
            else if (route is PackRoute)
                return new MaterialPageRoute(
                    settings: settings,
                    builder: (context) => new RootWidgetMock(
                        child: new PackScreen(storage, packId: route.params.packId, 
                            refreshed: route.params.refreshed))
                );

            return new MaterialPageRoute(
                settings: settings,
                builder: (context) => new RootWidgetMock(child: _buildPackListScreen(storage))
            );
        }));

    await tester.pump(new Duration(milliseconds: 500));

    final finder = find.byIcon(Icons.library_books);
    await new WidgetAssistant(tester).tapWidget(finder);

    return storage;
}

Future<StoredPack> _getFirstPackWithCards(PackStorageMock storage, WidgetTester tester) async => 
    await tester.runAsync<StoredPack>(
        () async => (await storage.fetch()).firstWhere((p) => p.cardsNumber > 0 
            && p.name != StoredPack.noneName));

Future<void> _testShowingCardsWithoutChanging(WidgetTester tester, 
    PackStorageMock storage, StoredPack pack) async {
    final expectedNumberOfCards = pack.cardsNumber;
        
    final assistant = new WidgetAssistant(tester);

    final packName = pack.name;
    await _goToCardList(assistant, packName);

    expect(find.byType(Dismissible), findsNWidgets(expectedNumberOfCards));

    await _goBackToPackList(assistant, packName);

    await _assertPackCardNumber(tester, storage, pack, expectedNumberOfCards);
}

Future<void> _testDecreasingNumberOfCards(WidgetTester tester, 
    PackStorageMock storage, StoredPack pack) async {
    final expectedNumberOfCards = pack.cardsNumber - 1;
    
    final assistant = new WidgetAssistant(tester);
    await _goToCardList(assistant, pack.name);

    tester.widget<Dismissible>(find.byType(Dismissible).first)
        .onDismissed.call(DismissDirection.endToStart);
    
    await _goBackToPackList(assistant, pack.name);

    await _assertPackCardNumber(tester, storage, pack, expectedNumberOfCards);
}

Future<void> _testIncreasingNumberOfCards(WidgetTester tester, 
    PackStorageMock storage, StoredPack pack) async {
    final expectedNumberOfCards = pack.cardsNumber + 1;

    final assistant = new WidgetAssistant(tester);
    await _goToCardList(assistant, pack.name);

    await tester.runAsync(() async {
        final randomWord = WordStorageMock.generateWord(packId: pack.id, hasNoPack: pack.isNone);
        await storage.wordStorage.update([randomWord]);
    });

    await _goBackToPackList(assistant, pack.name);

    await _assertPackCardNumber(tester, storage, pack, expectedNumberOfCards);
}

Future<void> _goToCardList(WidgetAssistant assistant, String packName) async {
    final tileWithCardsFinder = _findPackTileByName(packName);
    expect(tileWithCardsFinder, findsOneWidget);
    await assistant.tapWidget(tileWithCardsFinder);

    if (packName == StoredPack.noneName) 
        return;

    final cardListBtnFinder = find.byIcon(Icons.filter_1);
    expect(cardListBtnFinder, findsOneWidget);
    await assistant.tapWidget(cardListBtnFinder);
}

Finder _findPackTileByName(String name) {
    final nonePackTileFinder = find.ancestor(of: find.text(name), 
        matching: find.byType(ListTile), matchRoot: true);
    expect(nonePackTileFinder, findsOneWidget);

    return nonePackTileFinder;
}

Future<void> _goBackToPackList(WidgetAssistant assistant, String packName) async {
    await _goBack(assistant);

    if (packName == StoredPack.noneName) 
        return;

    await _goBack(assistant);
}

Future<void> _goBack(WidgetAssistant assistant) async {
    final backBtnFinders = find.byType(BackButton);
    assistant.tester.widget<BackButton>(backBtnFinders.first).onPressed.call();

    await assistant.pumpAndAnimate();
}

Future<void> _assertPackCardNumber(WidgetTester tester, PackStorageMock storage, 
    StoredPack pack, int expectedNumber) async {
    final tileWithCardsFinder = find.ancestor(of: find.text(pack.name), 
        matching: find.byType(ListTile));
    expect(tileWithCardsFinder, findsOneWidget);
    
    expect(find.descendant(of: tileWithCardsFinder, 
        matching: find.text(new CardNumberIndicator(expectedNumber).data)), 
        findsOneWidget);

    await tester.runAsync(() async {
        final actualPackWithCards = await storage.find(pack.id);
        expect(actualPackWithCards?.cardsNumber, expectedNumber);
    });
}

Future<StoredPack> _getNonePack(PackStorageMock storage, WidgetTester tester) async => 
    await tester.runAsync<StoredPack>(
        () async => (await storage.fetch()).firstWhere((p) => p.name == StoredPack.noneName));
