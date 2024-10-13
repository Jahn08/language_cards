import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/consts.dart';
import 'package:language_cards/src/data/dictionary_provider.dart';
import 'package:language_cards/src/data/word_dictionary.dart';
import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/part_of_speech.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/card_screen.dart';
import 'package:language_cards/src/widgets/bar_scaffold.dart';
import 'package:language_cards/src/widgets/styled_text_field.dart';
import '../../mocks/dictionary_provider_mock.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/root_widget_mock.dart';
import '../../mocks/speaker_mock.dart';
import '../../mocks/word_storage_mock.dart';
import '../../testers/card_editor_tester.dart';
import '../../testers/dialog_tester.dart';
import '../../testers/selector_dialog_tester.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/widget_assistant.dart';

void main() {
  testWidgets('Builds a screen displaying fields for a word from a storage',
      (tester) async {
    final wordToShow = await _displayFilledWord(tester);
    new CardEditorTester(tester).assureRenderingCardFields(wordToShow!);
  });

  testWidgets('Displays a card pack for a word from a storage', (tester) async {
    final expectedPack = PackStorageMock.generatePack(
        Randomiser.nextInt(PackStorageMock.namedPacksNumber));
    await _displayFilledWord(tester, pack: expectedPack);

    await _testDisplayingPackName(tester, expectedPack);
  });

  testWidgets(
      'Displays no button showing study progress for a card with the zero progress',
      (tester) async {
    final storage = new PackStorageMock();
    final wordWithoutProgress = storage.wordStorage.getRandom();
    if (wordWithoutProgress.studyProgress != WordStudyStage.unknown)
      wordWithoutProgress.resetStudyProgress();

    await _displayFilledWord(tester,
        storage: storage, wordToShow: wordWithoutProgress);

    CardEditorTester.findStudyProgressButton(shouldFind: false);
  });

  testWidgets(
      'Displays a button showing study progress for a card and resetting it',
      (tester) async {
    final storage = new PackStorageMock();
    late StoredWord wordWithProgress;
    await tester.runAsync(() async {
      final words = await storage.wordStorage.fetch();
      wordWithProgress = words.firstWhere(
          (w) => w.studyProgress != WordStudyStage.unknown,
          orElse: () => words.first);

      if (wordWithProgress.studyProgress == WordStudyStage.unknown)
        await storage.wordStorage
            .updateWordProgress(wordWithProgress.id!, WordStudyStage.learned);
    });

    await _displayFilledWord(tester,
        storage: storage, wordToShow: wordWithProgress);

    new CardEditorTester(tester)
        .assureNonZeroStudyProgress(wordWithProgress.studyProgress);

    final assistant = new WidgetAssistant(tester);

    await assistant
        .tapWidget(CardEditorTester.findStudyProgressButton(shouldFind: true));
    CardEditorTester.findStudyProgressButton(shouldFind: false);

    await _saveCard(assistant);

    final changedWord = await storage.wordStorage.find(wordWithProgress.id);
    expect(changedWord!.studyProgress, WordStudyStage.unknown);
  });

  testWidgets(
      'Displays no card pack name for a word from a storage without a pack',
      (tester) async {
    await _testDisplayingPackName(tester, StoredPack.none);
  });

  testWidgets(
      'Displays a currently chosen pack as highlighted in the dialog and changes it',
      (tester) async {
    final storage = new PackStorageMock();
    final expectedPack = storage.getRandom();
    await _displayFilledWord(tester, storage: storage, pack: expectedPack);

    final assistant = new WidgetAssistant(tester);
    final packBtnFinder = CardEditorTester.findPackButton();
    await assistant.tapWidget(packBtnFinder);

    final packTileFinder =
        CardEditorTester.findListTileByTitle(expectedPack.name);
    _assureTileIsTicked(packTileFinder);

    late StoredPack anotherExpectedPack;
    await tester.runAsync(() async => anotherExpectedPack =
        await _fetchAnotherPack(storage, expectedPack.id));
    final anotherPackTileFinder =
        CardEditorTester.findListTileByTitle(anotherExpectedPack.name);
    await assistant.tapWidget(anotherPackTileFinder);

    await assistant.tapWidget(packBtnFinder);

    _assureTileIsTicked(anotherPackTileFinder);
  });

  testWidgets('Displays all named packs in the pack selector dialog',
      (tester) async {
    final storage = new PackStorageMock(packsNumber: 30);
    await _displayFilledWord(tester,
        storage: storage,
        pack: storage.getRandom(),
        speaker: const SpeakerMock());

    final assistant = new WidgetAssistant(tester);
    final packBtnFinder = CardEditorTester.findPackButton();
    await assistant.tapWidget(packBtnFinder);

    final packs = await tester.runAsync(() => storage.fetch());
    packs!.forEach((p) {
      if (p.isNone) return;

      CardEditorTester.findListTileByTitle(p.name);
    });
  });

  testWidgets(
      'Displays all named packs filtered by a language pair in the pack selector dialog',
      (tester) async {
    final packStorage = new PackStorageMock(singleLanguagePair: false);
    final langPairs = await packStorage.fetchLanguagePairs();
    final expectedLangPair = langPairs.first;

    await _displayFilledWord(tester,
        storage: packStorage,
        pack: packStorage.getRandom(),
        speaker: const SpeakerMock(),
        langPair: expectedLangPair);

    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(CardEditorTester.findPackButton());

    final packs = await packStorage.fetch(languagePair: expectedLangPair);
    final packNames = packs.map((p) => p.name).toSet();
    SelectorDialogTester.assureRenderedOptions(tester, packs, (finder, _) {
      final itemTitleFinder =
          find.descendant(of: finder, matching: find.byType(Text));
      final itemTitle = tester.widget<Text>(itemTitleFinder.first);
      expect(packNames.contains(itemTitle.data), true);
    }, ListTile);
  });

  testWidgets(
      'Displays no button to pronounce card text if there is no pack and shows it otherwise',
      (tester) async {
    final storage = new PackStorageMock();
    await _displayFilledWord(tester,
        storage: storage, pack: StoredPack.none, speaker: const SpeakerMock());
    CardEditorTester.findSpeakerButton(shouldFind: false);

    await _changePack(
        tester, () => _fetchAnotherPack(storage, StoredPack.none.id));
    CardEditorTester.findSpeakerButton(shouldFind: true);

    await _changePack(tester, () => Future.value(StoredPack.none));
    CardEditorTester.findSpeakerButton(shouldFind: false);
  });

  testWidgets(
      'Displays no button to pronounce card text with empty text and shows it otherwise',
      (tester) async {
    final storage = new PackStorageMock();
    final pack = storage.getRandom();
    await _displayFilledWord(tester,
        storage: storage,
        pack: pack,
        wordToShow: WordStorageMock.generateWord(packId: pack.id),
        speaker: const SpeakerMock());
    CardEditorTester.findSpeakerButton(shouldFind: false);

    final assistant = new WidgetAssistant(tester);
    final newText = Randomiser.nextString();
    await _changeCardText(assistant, '', newText);
    CardEditorTester.findSpeakerButton(shouldFind: true);

    await _changeCardText(assistant, newText, '');
    CardEditorTester.findSpeakerButton(shouldFind: false);
  });

  testWidgets('Pronounces card text when clicking the speaker button',
      (tester) async {
    final storage = new PackStorageMock();
    final pack = storage.getRandom();
    final card = storage.wordStorage.getRandom();

    late String spokenText;
    await _displayFilledWord(tester,
        storage: storage,
        pack: pack,
        wordToShow: card,
        speaker: new SpeakerMock(onSpeak: (text) => spokenText = text));

    await new WidgetAssistant(tester)
        .tapWidget(CardEditorTester.findSpeakerButton(shouldFind: true));
    expect(spokenText, card.text);
  });

  testWidgets(
      'Switches focus to the translation field after changes in the word text field',
      (tester) async {
    final wordToShow = await _displayFilledWord(tester);
    await _testRefocusingChangedValues(
        tester, wordToShow!.text, wordToShow.translation!);
  });

  testWidgets(
      'Switches focus to the word text after changes in the translation field',
      (tester) async {
    final wordToShow = await _displayFilledWord(tester);
    await _testRefocusingChangedValues(
        tester, wordToShow!.translation!, wordToShow.text);
  });

  testWidgets(
      'Switches focus to the transcription field after changes in another text field',
      (tester) async {
    final wordToShow = await _displayFilledWord(tester);
    await _testRefocusingChangedValues(
        tester, wordToShow!.text, wordToShow.transcription);
  });

  testWidgets(
      'Switches focus to another text field after changes in the transcription field',
      (tester) async {
    final wordToShow = (await _displayFilledWord(tester))!;

    final assistant = new WidgetAssistant(tester);
    await _showTranscriptionKeyboard(assistant, wordToShow.transcription);

    final expectedChangedTr =
        await _changeTranscription(tester, wordToShow.transcription);

    final refocusedFieldFinder =
        find.widgetWithText(TextField, wordToShow.text);
    await new WidgetAssistant(tester).tapWidget(refocusedFieldFinder);

    expect(find.widgetWithText(TextField, expectedChangedTr), findsOneWidget);

    final refocusedField = tester.widget<TextField>(refocusedFieldFinder);
    expect(refocusedField.focusNode!.hasFocus, true);
  });

  testWidgets('Saves a new card', (tester) async {
    final storage = new PackStorageMock();

    await _displayWord(tester, storage, shouldHideWarningDialog: false);

    final assistant = new WidgetAssistant(tester);

    final textFields =
        AssuredFinder.findSeveral(type: StyledTextField, shouldFind: true);
    final cardText = Randomiser.nextString();
    await assistant.enterText(textFields.first, cardText);

    final translation = Randomiser.nextString();
    await assistant.enterText(textFields.last, translation);
    await _saveCard(assistant);

    final cards = await storage.wordStorage.fetch(textFilter: cardText);
    expect(cards.length, 1);
    expect(cards.first.translation, translation);
  });

  testWidgets(
      'Saves nothing when changes to the word text field have not been accepted yet',
      (tester) => _testSavingChangedValue(tester, (word) => word.text));

  testWidgets(
      'Saves nothing when changes to the word translation field have not been accepted yet',
      (tester) => _testSavingChangedValue(tester, (word) => word.translation!));

  testWidgets(
      'Saves nothing when changes to the word transcription field have not been accepted yet',
      (tester) async {
    final storage = new PackStorageMock();
    final wordToShow = await _displayFilledWord(tester, storage: storage);

    final assistant = new WidgetAssistant(tester);
    final initialValue = wordToShow!.transcription;
    await _showTranscriptionKeyboard(assistant, initialValue);

    final changedValue = await _changeTranscription(tester, initialValue);
    await _saveCard(assistant);

    final changedWord = await storage.wordStorage.find(wordToShow.id);
    expect(changedWord?.transcription, initialValue);
    expect(changedWord?.transcription == changedValue, false);
  });

  testWidgets('Saves a new pack for a card', (tester) async {
    final storage = new PackStorageMock();
    final wordToShow = (await _displayFilledWord(tester, storage: storage))!;

    final expectedPack = await _changePack(
        tester, () => _fetchAnotherPack(storage, wordToShow.packId));
    await new WidgetAssistant(tester)
        .pressButtonDirectly(CardEditorTester.findSaveButton());

    final changedWord = await storage.wordStorage.find(wordToShow.id);
    expect(changedWord == null, false);
    expect(changedWord!.packId, expectedPack.id);
  });

  testWidgets(
      'Returns back to the previous pack card list after saving a new pack',
      (tester) async {
    final storage = new PackStorageMock();
    await tester.pumpWidget(
        RootWidgetMock.buildAsAppHomeWithNonStudyRouting(storage: storage));
    await tester.pump(const Duration(milliseconds: 500));

    final packListBtnFinder = find.byIcon(Consts.packListIcon);
    await new WidgetAssistant(tester).tapWidget(packListBtnFinder);

    final pack = await _fetchAnotherPack(storage, StoredPack.none.id);
    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(find.widgetWithText(ListTile, pack.name));

    final cardListBtnFinder = find.byIcon(Consts.cardListIcon);
    await new WidgetAssistant(tester).tapWidget(cardListBtnFinder);
    await assistant.tapWidget(find.byType(ListTile).first);

    await _changePack(tester, () => Future.value(StoredPack.none));
    await new WidgetAssistant(tester)
        .pressButtonDirectly(CardEditorTester.findSaveButton());

    expect(
        pack.name
            .startsWith(tester.widget<BarTitle>(find.byType(BarTitle)).title!),
        true);
  });

  testWidgets(
      'Shows a warning for a card without a pack and turns off dictionaries',
      (tester) => _testInitialDictionaryState(tester, hasPack: false));

  testWidgets(
      'Shows a warning after nullifying a pack and turns off dictionaries',
      (tester) => _testChangingDictionaryState(tester, nullifyPack: true));

  testWidgets(
      'Turns on dictionaries and shows no warnings when a card has a pack',
      (tester) => _testInitialDictionaryState(tester, hasPack: true));

  testWidgets(
      'Turns on dictionaries and shows no warnings after choosing a pack',
      (tester) => _testChangingDictionaryState(tester, nullifyPack: false));

  testWidgets('Shows no popup initially when focusing on the word text field',
      (tester) async {
    final dicProviderMock = _createDictionaryProvider();
    final wordText =
        (await _displayWordWithPack(tester, provider: dicProviderMock))!.text;

    await _focusTextField(new WidgetAssistant(tester), wordText);
    AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
  });

  testWidgets('Shows no popup for a word without a pack', (tester) async {
    final dicProviderMock = _createDictionaryProvider();
    final wordText = (await _displayFilledWord(tester,
            provider: dicProviderMock, pack: StoredPack.none))!
        .text;
    await new WidgetAssistant(tester).enterChangedText(wordText);

    AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
  });

  testWidgets(
      'Shows no popup when the text field is empty or made up of spaces',
      (tester) async {
    final dicProviderMock = _createDictionaryProvider();
    final wordText =
        (await _displayWordWithPack(tester, provider: dicProviderMock))!.text;

    final assistant = new WidgetAssistant(tester);
    final changedText =
        await assistant.enterChangedText(wordText, changedText: '   ');
    AssuredFinder.findSeveral(type: ListTile, shouldFind: false);

    await assistant.enterChangedText(changedText, changedText: '');
    AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
  });

  testWidgets('Shows no popup when there are no suggestions for a word',
      (tester) async {
    final dicProviderMock = _createDictionaryProvider([]);
    final wordText =
        (await _displayWordWithPack(tester, provider: dicProviderMock))!.text;
    await new WidgetAssistant(tester).enterChangedText(wordText);

    AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
  });

  const lemmaLimit = WordDictionary.searcheableLemmaMaxNumber;
  testWidgets(
      'Suggests up to $lemmaLimit words to choose from a dictionary in a popup when editing the text field',
      (tester) async {
    final popupValues = Randomiser.nextStringList(
        minLength: lemmaLimit + 2, maxLength: lemmaLimit + 5);
    final dicProviderMock = _createDictionaryProvider(popupValues);

    final wordText =
        (await _displayWordWithPack(tester, provider: dicProviderMock))!.text;
    await new WidgetAssistant(tester).enterChangedText(wordText);

    final foundTiles = tester
        .widgetList<ListTile>(
            AssuredFinder.findSeveral(type: ListTile, shouldFind: true))
        .map((t) => (t.title! as Text).data)
        .toSet();
    expect(foundTiles.length, lemmaLimit);
    expect(popupValues.where((v) => foundTiles.contains(v)).length, lemmaLimit);
  });

  testWidgets(
      'Closes the suggestion popup after opting for a word there and displays its chosen text',
      (tester) async {
    final dicProviderMock = _createDictionaryProvider();
    final wordText =
        (await _displayWordWithPack(tester, provider: dicProviderMock))!.text;

    final assistant = new WidgetAssistant(tester);
    await assistant.enterChangedText(wordText);

    final tileFinder =
        AssuredFinder.findSeveral(type: ListTile, shouldFind: true).first;
    final expectedText =
        (tester.widget<ListTile>(tileFinder).title! as Text).data;

    await assistant.tapWidget(tileFinder.first);

    AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
    AssuredFinder.findOne(
        type: TextField, label: expectedText, shouldFind: true);
  });

  testWidgets('Closes the suggestion popup after the field gets unfocused',
      (tester) async {
    final dicProviderMock = _createDictionaryProvider();
    final shownWord =
        await _displayWordWithPack(tester, provider: dicProviderMock);

    await new WidgetAssistant(tester).enterChangedText(shownWord!.text);
    AssuredFinder.findSeveral(type: ListTile, shouldFind: true);

    await _focusTextField(new WidgetAssistant(tester), shownWord.translation!);
    AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
  });

  testWidgets('Merges translations of a duplicate with only one given card',
      (tester) async {
    final storage = new PackStorageMock();
    final wordStorage = storage.wordStorage;

    final defaultPack = storage.getRandom();
    final cards = await _getDuplicatedCards(defaultPack.id, wordStorage);
    final cardToShow = cards.first;

    final duplicatedCard = cards.last;
    final duplicateTranslation = duplicatedCard.translation;
    await _updateCard(wordStorage, duplicatedCard,
        newPos: cardToShow.partOfSpeech);

    final pack = await storage.find(cardToShow.packId);
    await _displayFilledWord(tester,
        storage: storage, wordToShow: cardToShow, pack: pack);

    final assistant = new WidgetAssistant(tester);
    final initialText = cardToShow.text;
    final initialTranslation = cardToShow.translation;

    await _changeCardText(assistant, cardToShow.text, duplicatedCard.text);
    await _saveCard(assistant);

    final mergeConfirmationBtnFinder = DialogTester.findConfirmationDialogBtn(
        Localizator.defaultLocalization
            .cardEditorDuplicatedCardDialogConfirmationButtonLabel);
    await assistant.tapWidget(mergeConfirmationBtnFinder);

    final nonChangedWord = await storage.wordStorage.find(cardToShow.id);
    expect(nonChangedWord!.text, initialText);
    expect(nonChangedWord.translation, initialTranslation);

    final mergedWord = await storage.wordStorage.find(duplicatedCard.id);
    expect(mergedWord!.translation!.startsWith(duplicateTranslation!), true);
    expect(mergedWord.translation!.endsWith(initialTranslation!), true);
  });

  testWidgets('Merges translations of a duplicate with a chosen card',
      (tester) async {
    final storage = new PackStorageMock();
    final wordStorage = storage.wordStorage;

    final defaultPack = storage.getRandom();
    final cards = await _getDuplicatedCards(defaultPack.id, wordStorage, 3);
    final cardToShow = cards.first;

    final duplicatedCardA = cards.last;
    final duplicatedText = duplicatedCardA.text;
    final duplicateTranslationA = duplicatedCardA.translation;

    final duplicatedCardB = cards.elementAt(1);
    final duplicateTranslationB = duplicatedCardB.translation;

    final pack = await storage.find(cardToShow.packId);
    await _displayFilledWord(tester,
        storage: storage, wordToShow: cardToShow, pack: pack);

    final assistant = new WidgetAssistant(tester);
    final initialText = cardToShow.text;
    final initialTranslation = cardToShow.translation;

    await _changeCardText(assistant, cardToShow.text, duplicatedText);
    await _saveCard(assistant);

    final mergeConfirmationBtnFinder = DialogTester.findConfirmationDialogBtn(
        Localizator.defaultLocalization
            .cardEditorDuplicatedCardDialogConfirmationButtonLabel);
    await assistant.tapWidget(mergeConfirmationBtnFinder);

    final itemToMergeFinder =
        AssuredFinder.findOne(label: duplicateTranslationA, shouldFind: true);
    AssuredFinder.findOne(label: duplicateTranslationB, shouldFind: true);

    await assistant.tapWidget(itemToMergeFinder);
    await assistant.pumpAndAnimate(500);

    final nonChangedWord = await storage.wordStorage.find(cardToShow.id);
    expect(nonChangedWord!.text, initialText);
    expect(nonChangedWord.translation, initialTranslation);

    final mergedWord = await storage.wordStorage.find(duplicatedCardA.id);
    expect(mergedWord!.translation!.startsWith(duplicateTranslationA!), true);
    expect(mergedWord.translation!.endsWith(initialTranslation!), true);

    final nonMergedWord = await storage.wordStorage.find(duplicatedCardB.id);
    expect(nonMergedWord!.translation, duplicateTranslationB);
  });

  testWidgets(
      'Cancels merging and saving when clicking outside the dialog for merging translations',
      (tester) async {
    final storage = new PackStorageMock();
    final wordStorage = storage.wordStorage;

    final defaultPack = storage.getRandom();
    final cards = await _getDuplicatedCards(defaultPack.id, wordStorage, 3);
    final cardToShow = cards.first;

    final duplicatedCardA = cards.last;
    final duplicatedText = duplicatedCardA.text;
    final duplicateTranslationA = duplicatedCardA.translation;

    final duplicatedCardB = cards.elementAt(1);
    final duplicateTranslationB = duplicatedCardB.translation;

    final pack = await storage.find(cardToShow.packId);
    await _displayFilledWord(tester,
        storage: storage, wordToShow: cardToShow, pack: pack);

    final assistant = new WidgetAssistant(tester);
    final initialText = cardToShow.text;
    final initialTranslation = cardToShow.translation;

    await _changeCardText(assistant, cardToShow.text, duplicatedText);
    await _saveCard(assistant);

    final mergeConfirmationBtnFinder = DialogTester.findConfirmationDialogBtn(
        Localizator.defaultLocalization
            .cardEditorDuplicatedCardDialogConfirmationButtonLabel);
    await assistant.tapWidget(mergeConfirmationBtnFinder);

    await _focusTextField(
        new WidgetAssistant(assistant.tester), cardToShow.translation!);
    AssuredFinder.findOne(label: duplicateTranslationA, shouldFind: false);
    AssuredFinder.findOne(label: duplicateTranslationB, shouldFind: false);

    final nonChangedWord = await storage.wordStorage.find(cardToShow.id);
    expect(nonChangedWord!.text, initialText);
    expect(nonChangedWord.translation, initialTranslation);

    final nonMergedWordA = await storage.wordStorage.find(duplicatedCardA.id);
    expect(nonMergedWordA!.translation, duplicateTranslationA);

    final nonMergedWordB = await storage.wordStorage.find(duplicatedCardB.id);
    expect(nonMergedWordB!.translation, duplicateTranslationB);
  });

  testWidgets('Desagrees to merge translations and saves a duplicated card',
      (tester) async {
    final storage = new PackStorageMock();
    final wordStorage = storage.wordStorage;

    final defaultPack = storage.getRandom();
    final cards = await _getDuplicatedCards(defaultPack.id, wordStorage);
    final cardToShow = cards.first;

    final duplicatedCard = cards.last;
    final duplicateTranslation = duplicatedCard.translation;
    final duplicatedText = duplicatedCard.text;
    await _updateCard(wordStorage, duplicatedCard,
        newPos: cardToShow.partOfSpeech);

    final pack = await storage.find(cardToShow.packId);
    await _displayFilledWord(tester,
        storage: storage, wordToShow: cardToShow, pack: pack);

    final assistant = new WidgetAssistant(tester);
    final initialTranslation = cardToShow.translation;

    await _changeCardText(assistant, cardToShow.text, duplicatedCard.text);
    await _saveCard(assistant);

    final mergeConfirmationBtnFinder = DialogTester.findConfirmationDialogBtn(
        Localizator.defaultLocalization
            .cardEditorDuplicatedCardDialogCancellationButtonLabel);
    await assistant.tapWidget(mergeConfirmationBtnFinder);

    final changedWord = await storage.wordStorage.find(cardToShow.id);
    expect(changedWord!.text, duplicatedText);
    expect(changedWord.translation, initialTranslation);

    final nonMergedWord = await storage.wordStorage.find(duplicatedCard.id);
    expect(nonMergedWord!.text, duplicatedText);
    expect(nonMergedWord.translation, duplicateTranslation);
  });
}

Future<StoredWord?> _displayFilledWord(WidgetTester tester,
    {DictionaryProvider? provider,
    PackStorageMock? storage,
    StoredPack? pack,
    StoredWord? wordToShow,
    SpeakerMock? speaker,
    LanguagePair? langPair,
    bool shouldHideWarningDialog = true}) async {
  storage ??= new PackStorageMock();
  final wordStorage = storage.wordStorage;
  wordToShow ??= wordStorage.getRandom();

  return _displayWord(tester, storage,
      provider: provider,
      pack: pack,
      wordToShow: wordToShow,
      speaker: speaker,
      langPair: langPair,
      shouldHideWarningDialog: shouldHideWarningDialog);
}

Future<StoredWord?> _displayWord(WidgetTester tester, PackStorageMock storage,
    {DictionaryProvider? provider,
    StoredPack? pack,
    StoredWord? wordToShow,
    SpeakerMock? speaker,
    LanguagePair? langPair,
    bool shouldHideWarningDialog = true}) async {
  await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
      childBuilder: (context) => new CardScreen(
          wordStorage: storage.wordStorage,
          packStorage: storage,
          wordId: wordToShow?.id,
          pack: pack,
          languagePair: langPair,
          provider: provider ?? _createDictionaryProvider([]),
          defaultSpeaker: speaker ?? const SpeakerMock())));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));

  if (shouldHideWarningDialog) {
    final nonePack = StoredPack.none;
    final warningIsExpected =
        pack == nonePack || (pack == null && wordToShow?.packId == nonePack.id);
    final emptyPackWarnDialogBtnFinder =
        _findWarningDialogButton(shouldFind: warningIsExpected);
    if (warningIsExpected)
      await new WidgetAssistant(tester).tapWidget(emptyPackWarnDialogBtnFinder);
  }

  return wordToShow;
}

DictionaryProvider _createDictionaryProvider([Iterable<String>? lemmas]) =>
    new DictionaryProviderMock(
        onSearchForLemmas: (text) => lemmas ?? Randomiser.nextStringList());

Finder _findWarningDialogButton({bool? shouldFind}) {
  final dialogBtnFinder = DialogTester.findConfirmationDialogBtn();
  expect(dialogBtnFinder, AssuredFinder.matchOne(shouldFind: shouldFind));

  return dialogBtnFinder;
}

Future<void> _testRefocusingChangedValues(WidgetTester tester,
    String fieldValueToChange, String fieldValueToRefocus) async {
  final expectedChangedText =
      await new WidgetAssistant(tester).enterChangedText(fieldValueToChange);

  final refocusedFieldFinder =
      await _focusTextField(new WidgetAssistant(tester), fieldValueToRefocus);

  final initiallyFocusedFieldFinder =
      find.widgetWithText(TextField, expectedChangedText);
  expect(initiallyFocusedFieldFinder, findsOneWidget);

  final refocusedField = tester.widget<TextField>(refocusedFieldFinder);
  expect(refocusedField.focusNode!.hasFocus, true);
}

Future<Finder> _focusTextField(
    WidgetAssistant assistant, String textToFocus) async {
  final refocusedFieldFinder = find.widgetWithText(TextField, textToFocus);
  await assistant.tapWidget(refocusedFieldFinder);
  return refocusedFieldFinder;
}

Future<void> _testSavingChangedValue(WidgetTester tester,
    String Function(StoredWord) valueToChangeGetter) async {
  final storage = new PackStorageMock();
  final wordToShow = await _displayFilledWord(tester, storage: storage);

  final assistant = new WidgetAssistant(tester);

  final initialValue = valueToChangeGetter(wordToShow!);
  final changedText = await assistant.enterChangedText(initialValue);

  await assistant.tapWidget(CardEditorTester.findSaveButton());

  final changedWord = await storage.wordStorage.find(wordToShow.id);
  expect(changedWord == null, false);
  expect(valueToChangeGetter(changedWord!), initialValue);
  expect(valueToChangeGetter(changedWord) == changedText, false);
}

Future<void> _showTranscriptionKeyboard(
    WidgetAssistant assistant, String transcription) async {
  final transcriptionFinder = find.widgetWithText(TextField, transcription);
  expect(transcriptionFinder, findsOneWidget);

  await assistant.tapWidget(transcriptionFinder);
}

Future<String> _changeTranscription(
    WidgetTester tester, String curTranscription) async {
  final expectedSymbols =
      await new CardEditorTester(tester).enterRandomTranscription();
  return curTranscription + expectedSymbols.join();
}

Future<void> _testDisplayingPackName(WidgetTester tester,
    [StoredPack? expectedPack]) async {
  await _displayFilledWord(tester, pack: expectedPack);

  new CardEditorTester(tester).assureRenderingPack(expectedPack);
}

Future<StoredPack> _fetchAnotherPack(PackStorageMock storage, int? curPackId,
        {bool canBeNonePack = false}) async =>
    (await storage.fetch()).firstWhere((p) =>
        p.cardsNumber > 0 && p.id != curPackId && (canBeNonePack || !p.isNone));

Future<StoredPack> _changePack(
    WidgetTester tester, Future<StoredPack> Function() newPackGetter) async {
  late StoredPack expectedPack;
  await tester.runAsync(() async => expectedPack = await newPackGetter());

  await new CardEditorTester(tester).changePack(expectedPack);

  return expectedPack;
}

void _assureTileIsTicked(Finder tileFinder) => expect(
    find.descendant(of: tileFinder, matching: find.byIcon(Icons.check)),
    findsOneWidget);

Future<void> _testInitialDictionaryState(WidgetTester tester,
    {required bool hasPack}) async {
  bool dictionaryIsActive = false;
  final dicProvider = new DictionaryProviderMock(onSearchForLemmas: (text) {
    dictionaryIsActive = true;
    return [];
  });

  final wordToShow = await _displayFilledWord(tester,
      provider: dicProvider,
      shouldHideWarningDialog: false,
      pack: hasPack
          ? PackStorageMock.generatePack(
              Randomiser.nextInt(PackStorageMock.namedPacksNumber))
          : StoredPack.none);

  await _assureWarningDialog(tester, !hasPack);

  await _inputTextAndAccept(tester, wordToShow!.text);

  expect(dictionaryIsActive, hasPack);
}

Future<void> _assureWarningDialog(WidgetTester tester, bool shouldFind) async {
  final warningBtnFinder = _findWarningDialogButton(shouldFind: shouldFind);

  if (shouldFind) await new WidgetAssistant(tester).tapWidget(warningBtnFinder);
}

Future<void> _inputTextAndAccept(WidgetTester tester, String wordText) async {
  final assistant = new WidgetAssistant(tester);
  final newText = await assistant.enterChangedText(wordText);
  final textFinder = find.widgetWithText(TextField, newText);

  tester.widget<TextField>(textFinder).onEditingComplete?.call();
  await assistant.pumpAndAnimate();
}

Future<void> _testChangingDictionaryState(WidgetTester tester,
    {required bool nullifyPack}) async {
  bool dictionaryIsActive = false;
  final dicProvider = new DictionaryProviderMock(onSearchForLemmas: (text) {
    dictionaryIsActive = true;
    return [];
  });

  final storage = new PackStorageMock();
  final wordToShow = await _displayFilledWord(tester,
      storage: storage,
      provider: dicProvider,
      pack: nullifyPack
          ? PackStorageMock.generatePack(
              Randomiser.nextInt(PackStorageMock.namedPacksNumber))
          : null);

  await _changePack(
      tester,
      () => nullifyPack
          ? Future.value(StoredPack.none)
          : _fetchAnotherPack(storage, wordToShow!.packId));

  await _assureWarningDialog(tester, nullifyPack);

  await _inputTextAndAccept(tester, wordToShow!.text);

  expect(dictionaryIsActive, !nullifyPack);
}

Future<StoredWord?> _displayWordWithPack(WidgetTester tester,
    {DictionaryProvider? provider,
    PackStorageMock? storage,
    StoredWord? wordToShow,
    SpeakerMock? speaker,
    bool shouldHideWarningDialog = true}) {
  storage ??= new PackStorageMock();

  return _displayFilledWord(tester,
      provider: provider,
      storage: storage,
      pack: storage.getRandom(),
      wordToShow: wordToShow,
      speaker: speaker,
      shouldHideWarningDialog: shouldHideWarningDialog);
}

Future<List<StoredWord>> _getDuplicatedCards(
    int? packId, WordStorageMock storage,
    [int take = 2]) async {
  final result = <StoredWord>[];

  final cards = await storage.fetch();

  String? duplicatedText;
  PartOfSpeech? pos;
  for (int i = 0; i < take; ++i) {
    final card = cards[i];
    pos ??= card.partOfSpeech;

    if (i == 1) duplicatedText = card.text;

    result.add(await _updateCard(storage, card,
        newPackId: card.packId == StoredPack.none.id ? packId : card.packId,
        newText: duplicatedText,
        newPos: pos));
  }

  return result;
}

Future<StoredWord> _updateCard(WordStorageMock wordStorage, StoredWord card,
    {PartOfSpeech? newPos, String? newText, int? newPackId}) async {
  if (card.partOfSpeech == (newPos ?? card.partOfSpeech) &&
      card.text == (newText ?? card.text) &&
      card.packId == (newPackId ?? card.packId)) return card;

  final updatedCard = new StoredWord(newText ?? card.text,
      id: card.id,
      packId: newPackId ?? card.packId,
      partOfSpeech: newPos ?? card.partOfSpeech,
      studyProgress: card.studyProgress,
      transcription: card.transcription,
      translation: card.translation);
  await wordStorage.upsert([updatedCard]);

  return updatedCard;
}

Future<void> _saveCard(WidgetAssistant assistant) =>
    assistant.pressButtonDirectly(CardEditorTester.findSaveButton());

Future<void> _changeCardText(
    WidgetAssistant assistant, String currentText, String newText) async {
  await assistant.enterChangedText(currentText, changedText: newText);

  final anotherTextField = find.byType(TextField).last;
  await assistant.tapWidget(anotherTextField);
}
