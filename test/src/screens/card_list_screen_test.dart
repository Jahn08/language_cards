import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/base_storage.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/card_list_screen.dart';
import 'package:language_cards/src/screens/list_screen.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/word_storage_mock.dart';
import '../../testers/dialog_tester.dart';
import '../../testers/list_screen_tester.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/storage_fetcher.dart';
import '../../utilities/widget_assistant.dart';

void main() {
  final screenTester = _buildScreenTester();
  screenTester.testEditorMode();
  screenTester.testSearchMode(
      (id) => WordStorageMock.generateWord(id: id), _groupCardsByTextIndex);

  screenTester.testDismissingItems();

  testWidgets("Sorts cards by normalized text", (tester) async {
    final packStorage = new PackStorageMock(cardsNumber: 10, packsNumber: 1);

    final wordTexts = ['café', 'apple', 'abacus', 'banana', 'ábaco'];
    
    final namedPacks = await StorageFetcher.fetchNamedPacks(packStorage);
    final chosenPack = namedPacks.first;
    final wordsByNamedPacks = await StorageFetcher.fetchPackedCards([chosenPack], packStorage.wordStorage);

    final updatedWords = wordsByNamedPacks.mapIndexed((i, w) => new StoredWord(
      wordTexts[i], id: w.id, packId: w.packId, partOfSpeech: w.partOfSpeech,
      studyProgress: w.studyProgress, transcription: w.transcription,
      translation: w.translation));
    await packStorage.wordStorage.upsert(updatedWords.toList());

    final screenTester = _buildScreenTester(packStorage: packStorage, pack: chosenPack);
    await screenTester.pumpScreen(tester);

    final listItemFinders = find.descendant(
        of: find.byType(Dismissible, skipOffstage: false),
        matching: find.byType(ListTile, skipOffstage: false),
        skipOffstage: false);

    final wordTextsOrdered = ['ábaco', 'abacus', 'apple', 'banana', 'café'];

    for (int i = 0; i < 5; ++i) {
      final expectedText = wordTextsOrdered[i];
      expect(
          find.descendant(
              of: listItemFinders.at(i),
              matching: find.text(expectedText, skipOffstage: false)),
          findsOneWidget);
    }
  });

  testWidgets("Renders cards filtered by a language pair", (tester) async {
    final packStorage =
        new PackStorageMock(singleLanguagePair: false, cardsNumber: 10);
    final langPairs = await packStorage.fetchLanguagePairs();
    final chosenLangPair = Randomiser.nextElement(langPairs);

    final screenTester =
        _buildScreenTester(packStorage: packStorage, langPair: chosenLangPair);
    await screenTester.pumpScreen(tester);

    final packsByLangPair =
        await packStorage.fetch(languagePair: chosenLangPair);
    final wordsByLangPair = await StorageFetcher.fetchPackedCards(
        packsByLangPair, packStorage.wordStorage);
    final itemsLength = wordsByLangPair.length;

    final listItemFinders = find.descendant(
        of: find.byType(Dismissible, skipOffstage: false),
        matching: find.byType(ListTile, skipOffstage: false),
        skipOffstage: false);
    expect(listItemFinders, findsNWidgets(itemsLength));

    for (int i = 0; i < itemsLength; ++i) {
      final word = wordsByLangPair[i];
      expect(
          find.descendant(
              of: listItemFinders.at(i),
              matching: find.text(word.text, skipOffstage: false)),
          findsOneWidget);
    }
  });

  testWidgets('Switches to the search mode for cards grouped by a pack',
      (tester) async {
    final packStorage = new PackStorageMock(cardsNumber: 70);
    final pack = (await packStorage.fetch())
        .firstWhere((p) => !p.isNone && p.cardsNumber > 0);
    final wordStorage = packStorage.wordStorage;

    final groupedScreenTester =
        _buildScreenTester(storage: wordStorage, pack: pack);
    final childCards = await wordStorage.fetchFiltered(parentIds: [pack.id]);

    int index = 0;
    await wordStorage.upsert(childCards
        .map((e) => new StoredWord((index++ % 2).toString() + e.text,
            id: e.id,
            packId: e.packId,
            partOfSpeech: e.partOfSpeech,
            studyProgress: e.studyProgress,
            transcription: e.transcription,
            translation: e.translation))
        .toList());

    await groupedScreenTester.testSwitchingToSearchMode(tester,
        newEntityGetter: (index) =>
            WordStorageMock.generateWord(id: 100 + index, packId: pack.id),
        itemsLengthGetter: () => Future.value(childCards.length),
        indexGroupsGetter: (_) async {
          final indexGroups =
              await wordStorage.groupByTextIndexAndParent([pack.id]);
          expect(indexGroups.length, 2);
          return indexGroups;
        },
        textIndexGetter: _groupCardsByTextIndex);
  });

  testWidgets('Renders study progress for each card', (tester) async {
    final wordStorage =
        await screenTester.pumpScreen(tester) as WordStorageMock;
    final words = await wordStorage.fetch();

    final listItemFinders = find.descendant(
        of: screenTester.tryFindingListItems(shouldFind: true),
        matching: find.byType(ListTile));
    final itemsLength = listItemFinders.evaluate().length;
    for (int i = 0; i < itemsLength; ++i) {
      final word = words[i];
      expect(
          find.descendant(
              of: listItemFinders.at(i),
              matching: find.text('${word.studyProgress}%')),
          findsOneWidget);
    }
  });

  testWidgets(
      "Cancels resetting study progress for selected cards when it wasn't confirmed",
      (tester) async {
    final wordStorage =
        await screenTester.pumpScreen(tester) as WordStorageMock;
    final wordWithProgressIndex =
        await _getIndexOfFirstWordWithProgress(tester, wordStorage);

    final assistant = new WidgetAssistant(tester);
    await screenTester.activateEditorMode(assistant);

    final selectedItems = (await screenTester.selectSomeItemsInEditor(
            assistant, wordWithProgressIndex))
        .values
        .toSet();
    final selectedWords = (await wordStorage.fetchFiltered())
        .where((w) => selectedItems.contains(w.text));
    final selectedWordsWithProgress = <String, int>{
      for (final w in selectedWords) w.text: w.studyProgress
    };
    await _operateResettingProgressDialog(assistant);

    await screenTester.deactivateEditorMode(assistant);
    final assuredWords =
        await _assureStudyProgressForWords(tester, screenTester, wordStorage);
    expect(
        selectedWordsWithProgress.entries.every((entry) => assuredWords.any(
            (word) =>
                word.text == entry.key && word.studyProgress == entry.value)),
        true);
  });

  testWidgets('Resets study progress for selected cards', (tester) async {
    final wordStorage =
        await screenTester.pumpScreen(tester) as WordStorageMock;
    final wordWithProgressIndex =
        await _getIndexOfFirstWordWithProgress(tester, wordStorage);

    final assistant = new WidgetAssistant(tester);
    await screenTester.activateEditorMode(assistant);

    final selectedItems = await screenTester.selectSomeItemsInEditor(
        assistant, wordWithProgressIndex);
    await _operateResettingProgressDialog(assistant, shouldConfirm: true);

    await screenTester.deactivateEditorMode(assistant);
    final assuredWords =
        await _assureStudyProgressForWords(tester, screenTester, wordStorage);
    expect(
        selectedItems.values.every((text) => assuredWords.any((word) =>
            word.text == text && word.studyProgress == WordStudyStage.unknown)),
        true);
  });

  testWidgets(
      'Shows no dialog to reset study progress for cards without progress',
      (tester) async {
    final storage = new WordStorageMock();
    final inScreenTester = _buildScreenTester(storage: storage);

    final words = await storage.fetchFiltered();
    words.forEach((w) => w.resetStudyProgress());
    await storage.upsert(words);

    await inScreenTester.pumpScreen(tester);

    final assistant = new WidgetAssistant(tester);
    await inScreenTester.activateEditorMode(assistant);

    await inScreenTester.selectSomeItemsInEditor(assistant);

    await _operateResettingProgressDialog(assistant,
        shouldConfirm: true, assureNoDialog: true);
  });

  testWidgets(
      'Selects all cards on a page and scrolls down until others get available to select them too',
      (tester) async {
    final packsStorage = new PackStorageMock(
        cardsNumber: (ListScreen.itemsPerPage * 1.5).toInt());
    await _testSelectingOnPage(tester, packsStorage.wordStorage);
  });

  testWidgets(
      'Shows the right number of cards for selection when there are cards in the none pack present and a language pair set',
      (tester) async {
    final packsStorage = new PackStorageMock(cardsNumber: 7);
    final words = await packsStorage.wordStorage.fetch();
    final wordWithPack = words.firstWhere((w) => w.packId != null);

    final wordsToAdd = List.generate(
        5,
        (i) => WordStorageMock.generateWord(
            id: i + 999,
            hasNoPack: true,
            textGetter: (_, __) => "${wordWithPack.text}$i"));
    await packsStorage.wordStorage.upsert(wordsToAdd);

    final pack = (await packsStorage.fetch())
        .firstWhere((p) => p.id == wordWithPack.packId);
    final inScreenTester = _buildScreenTester(
        storage: packsStorage.wordStorage,
        packStorage: packsStorage,
        langPair: new LanguagePair(pack.from!, pack.to!));
    await inScreenTester.pumpScreen(tester);

    final assistant = new WidgetAssistant(tester);
    await inScreenTester.activateEditorMode(assistant);

    final expectedCardNumberStr = await packsStorage.wordStorage.count();
    final locale = Localizator.defaultLocalization;
    expect(inScreenTester.getSelectorBtnLabel(tester),
        locale.constsSelectAll(expectedCardNumberStr.toString()));
  });

  testWidgets(
      'Deletes all cards on a page and then deletes some of the left ones available on other pages',
      (tester) async {
    final itemsOverall = (ListScreen.itemsPerPage * 1.5).toInt();
    final packsStorage = new PackStorageMock(cardsNumber: itemsOverall);
    final storage = packsStorage.wordStorage;

    final inScreenTester = _buildScreenTester(storage: storage);
    await inScreenTester.pumpScreen(tester);

    final assistant = new WidgetAssistant(tester);
    await inScreenTester.activateEditorMode(assistant);

    await inScreenTester.selectAll(assistant);
    await inScreenTester.deleteSelectedItems(assistant);
    inScreenTester.tryFindingListCheckTiles(shouldFind: true);

    final expectedCardsNumber = itemsOverall - ListScreen.itemsPerPage;
    final locale = Localizator.defaultLocalization;
    expect(inScreenTester.getSelectorBtnLabel(tester),
        locale.constsSelectAll(expectedCardsNumber.toString()));

    final deletedItems =
        await inScreenTester.selectSomeItemsInEditor(assistant);
    await inScreenTester.deleteSelectedItems(assistant);
    inScreenTester.tryFindingListCheckTiles(shouldFind: true);

    final finalCardsNumber = expectedCardsNumber - deletedItems.length;
    expect(inScreenTester.getSelectorBtnLabel(tester),
        locale.constsSelectAll(finalCardsNumber.toString()));
  });

  testWidgets(
      'Selects all grouped cards on a page and scrolls down until others get available to select them too',
      (tester) async {
    final packsStorage = new PackStorageMock(
        cardsNumber: (ListScreen.itemsPerPage * 2.1).toInt(), packsNumber: 2);
    await _testSelectingOnPage(
        tester, packsStorage.wordStorage, packsStorage.getRandom());
  });

  testWidgets(
      'Scrolls down till the end of a short list of cards without changing the number of cards available for selection',
      (tester) async {
    const int expectedCardsNumber = 15;
    final packsStorage = new PackStorageMock(cardsNumber: expectedCardsNumber);
    final inScreenTester =
        _buildScreenTester(storage: packsStorage.wordStorage);
    await inScreenTester.pumpScreen(tester);

    final assistant = new WidgetAssistant(tester);
    await assistant.scrollDownListView(find.byType(ListTile));
    await inScreenTester.activateEditorMode(assistant);

    expect(
        inScreenTester.getSelectorBtnLabel(tester),
        Localizator.defaultLocalization
            .constsSelectAll(expectedCardsNumber.toString()));
  });
}

ListScreenTester<StoredWord> _buildScreenTester(
    {WordStorageMock? storage,
    StoredPack? pack,
    PackStorageMock? packStorage,
    LanguagePair? langPair}) {
  return new ListScreenTester(
      'Card',
      ([cardsNumber]) => new CardListScreen(
          storage ??
              packStorage?.wordStorage ??
              new WordStorageMock(
                  cardsNumber: cardsNumber ?? 40,
                  textGetter: (text, id) => (id! % 2).toString() + text),
          pack: pack,
          packStorage: packStorage,
          languagePair: langPair));
}

Future<List<StoredWord>> _assureStudyProgressForWords(WidgetTester tester,
    ListScreenTester screenTester, WordStorageMock storage) async {
  final words = await storage.fetchFiltered();

  final assuredWords = <StoredWord>[];
  final listItemFinders = find.descendant(
      of: screenTester.tryFindingListItems(shouldFind: true),
      matching: find.byType(ListTile));
  final itemsLength = listItemFinders.evaluate().length;
  for (int i = 0; i < itemsLength; ++i) {
    final word = words[i];
    assuredWords.add(word);

    expect(
        find.descendant(
            of: listItemFinders.at(i),
            matching: find.text('${word.studyProgress}%')),
        findsOneWidget);
  }

  return assuredWords;
}

Finder _findRestoreBtn({bool? shouldFind}) =>
    AssuredFinder.findOne(icon: Icons.restore, shouldFind: shouldFind);

Finder _findBtnByLabel(String label, {bool shouldFind = true}) {
  final finder = DialogTester.findConfirmationDialogBtn(label);
  expect(finder, AssuredFinder.matchOne(shouldFind: shouldFind));

  return finder;
}

Future<void> _operateResettingProgressDialog(WidgetAssistant assistant,
    {bool shouldConfirm = false, bool assureNoDialog = false}) async {
  final restoreBtnFinder = _findRestoreBtn(shouldFind: true);
  await assistant.tapWidget(restoreBtnFinder);

  final actionBtnFinder = _findBtnByLabel(
      shouldConfirm
          ? 'Yes'
          : Localizator
              .defaultLocalization.cancellableDialogCancellationButtonLabel,
      shouldFind: !assureNoDialog);
  if (!assureNoDialog) await assistant.tapWidget(actionBtnFinder);
}

Future<int> _getIndexOfFirstWordWithProgress(
    WidgetTester tester, WordStorageMock storage) async {
  final words = (await storage.fetchFiltered()).toList();
  int wordWithProgressIndex =
      words.indexWhere((w) => w.studyProgress > WordStudyStage.unknown);

  if (wordWithProgressIndex == -1) {
    wordWithProgressIndex = 0;
    await storage.updateWordProgress(
        words[wordWithProgressIndex].id!, WordStudyStage.learned);
  }

  return wordWithProgressIndex;
}

Future<void> _testSelectingOnPage(WidgetTester tester, WordStorageMock storage,
    [StoredPack? pack]) async {
  final inScreenTester = _buildScreenTester(storage: storage, pack: pack);
  await inScreenTester.pumpScreen(tester);

  final assistant = new WidgetAssistant(tester);
  await inScreenTester.activateEditorMode(assistant);
  await inScreenTester.selectAll(assistant);

  final expectedCardNumberStr =
      (await storage.count(parentId: pack?.id)).toString();
  final locale = Localizator.defaultLocalization;
  expect(
      inScreenTester.getSelectorBtnLabel(tester),
      locale.constsUnselectSome(
          ListScreen.itemsPerPage.toString(), expectedCardNumberStr));

  await assistant.scrollDownListView(find.byType(CheckboxListTile),
      iterations: 35);
  expect(inScreenTester.getSelectorBtnLabel(tester),
      locale.constsSelectAll(expectedCardNumberStr));
  inScreenTester.assureSelectionForAllTilesInEditor(tester,
      onlyForSomeItems: true);

  await inScreenTester.selectAll(assistant);
  inScreenTester.assureSelectionForAllTilesInEditor(tester, selected: true);
}

Future<Map<String, int>> _groupCardsByTextIndex(
    BaseStorage<StoredWord> storage) async {
  final groups = <String, int>{};
  (await storage.fetch()).forEach((p) {
    if (p.id == null) return;

    final firstLetter = p.text[0];
    if (groups.containsKey(firstLetter))
      groups[firstLetter] = groups[firstLetter]! + 1;
    else
      groups[firstLetter] = 1;
  });

  return groups;
}
