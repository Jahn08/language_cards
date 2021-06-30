import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/dictionary_provider.dart';
import 'package:language_cards/src/data/web_dictionary_provider.dart';
import 'package:language_cards/src/data/word_dictionary.dart';
import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/card_screen.dart';
import '../../mocks/dictionary_provider_mock.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/root_widget_mock.dart';
import '../../mocks/speaker_mock.dart';
import '../../mocks/word_storage_mock.dart';
import '../../testers/card_editor_tester.dart';
import '../../testers/dialog_tester.dart';
import '../../testers/word_dictionary_tester.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/http_responder.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/widget_assistant.dart';

void main() {

    testWidgets('Builds a screen displaying fields for a word from a storage', 
        (tester) async {
            final wordToShow = await _displayWord(tester);
			new CardEditorTester(tester).assureRenderingCardFields(wordToShow);
        });

    testWidgets('Displays a card pack for a word from a storage', 
        (tester) async {
            final expectedPack = PackStorageMock.generatePack(
                Randomiser.nextInt(PackStorageMock.namedPacksNumber));
            await _displayWord(tester, pack: expectedPack);

            await _testDisplayingPackName(tester, expectedPack);
        });

    testWidgets('Displays no button showing study progress for a card with the zero progress', 
        (tester) async {
            final storage = new PackStorageMock();
            final wordWithoutProgress = storage.wordStorage.getRandom();
            if (wordWithoutProgress.studyProgress != WordStudyStage.unknown)
                wordWithoutProgress.resetStudyProgress();

            await _displayWord(tester, storage: storage, wordToShow: wordWithoutProgress);

            CardEditorTester.findStudyProgressButton(shouldFind: false);
        });

    testWidgets('Displays a button showing study progress for a card and resetting it', 
        (tester) async {
            final storage = new PackStorageMock();
            StoredWord wordWithProgress;
            await tester.runAsync(() async {
                final words = (await storage.wordStorage.fetch());
                wordWithProgress = words.firstWhere((w) => w.studyProgress != WordStudyStage.unknown, 
                    orElse: () => words.first);

                if (wordWithProgress.studyProgress == WordStudyStage.unknown)
                    await storage.wordStorage.updateWordProgress(wordWithProgress.id, 
                        WordStudyStage.learned);
            });

            await _displayWord(tester, storage: storage, wordToShow: wordWithProgress);

			new CardEditorTester(tester).assureNonZeroStudyProgress(
				wordWithProgress.studyProgress);

            final assistant = new WidgetAssistant(tester);

			await assistant.tapWidget(
				CardEditorTester.findStudyProgressButton(shouldFind: true));
            CardEditorTester.findStudyProgressButton(shouldFind: false);

            await assistant.pressButtonDirectly(CardEditorTester.findSaveButton());

            final changedWord = await storage.wordStorage.find(wordWithProgress.id);
            expect(changedWord.studyProgress, WordStudyStage.unknown);
        });

    testWidgets('Displays no card pack name for a word from a storage without a pack', 
        (tester) async {
            await _testDisplayingPackName(tester, StoredPack.none);
        });

    testWidgets('Displays a currently chosen pack as highlighted in the dialog and changes it', 
        (tester) async {
            final storage = new PackStorageMock();
            final expectedPack = storage.getRandom();
            await _displayWord(tester, storage: storage, pack: expectedPack);
            
            final assistant = new WidgetAssistant(tester);
            final packBtnFinder = CardEditorTester.findPackButton();
            await assistant.tapWidget(packBtnFinder);

            final packTileFinder = CardEditorTester.findListTileByTitle(expectedPack.name);
            _assureTileIsTicked(packTileFinder);

            StoredPack anotherExpectedPack;
            await tester.runAsync(() async => 
                anotherExpectedPack = await _fetchAnotherPack(storage, expectedPack.id));
            final anotherPackTileFinder = 
				CardEditorTester.findListTileByTitle(anotherExpectedPack.name);
            await assistant.tapWidget(anotherPackTileFinder);

            await assistant.tapWidget(packBtnFinder);

            _assureTileIsTicked(anotherPackTileFinder);
        });

	testWidgets('Displays all named packs in the pack selector dialog', (tester) async {
		final storage = new PackStorageMock(packsNumber: 30);
		await _displayWord(tester, storage: storage, pack: storage.getRandom());
		
		final assistant = new WidgetAssistant(tester);
		final packBtnFinder = CardEditorTester.findPackButton();
		await assistant.tapWidget(packBtnFinder);

		final packs = await tester.runAsync(() => storage.fetch());
		packs.forEach((p) {
			if (p.isNone)
				return;

			CardEditorTester.findListTileByTitle(p.name);
		});
	});

	testWidgets('Displays no button to pronounce card text if there is no pack', 
        (tester) async {
            await _displayWord(tester, pack: StoredPack.none);

			CardEditorTester.findSpeakerButton(shouldFind: false);
		});
	
	testWidgets('Displays no button to pronounce card text with empty text', 
        (tester) async {
			final storage = new PackStorageMock();
			final pack = storage.getRandom();
			await _displayWord(tester, storage: storage, pack: pack,
				wordToShow: WordStorageMock.generateWord(packId: pack.id));

			CardEditorTester.findSpeakerButton(shouldFind: false);
		});

	testWidgets('Displays a button to pronounce card text', 
        (tester) async {
			final storage = new PackStorageMock();
			final pack = storage.getRandom();
			final card = storage.wordStorage.getRandom();

			String spokenText;
			await _displayWord(tester, storage: storage, pack: pack, wordToShow: card,
				speaker: new SpeakerMock(onSpeak: (text) => spokenText = text));

			await new WidgetAssistant(tester).tapWidget(
				CardEditorTester.findSpeakerButton(shouldFind: true));
			expect(spokenText, card.text);
		});
	
    testWidgets('Switches focus to the translation field after changes in the word text field', 
        (tester) async {
            final wordToShow = await _displayWord(tester);
            await _testRefocusingChangedValues(tester, wordToShow.text, wordToShow.translation);
        });

    testWidgets('Switches focus to the word text after changes in the translation field', 
        (tester) async {
            final wordToShow = await _displayWord(tester);
            await _testRefocusingChangedValues(tester, wordToShow.translation, wordToShow.text);
        });

    testWidgets('Switches focus to the transcription field after changes in another text field', 
        (tester) async {
            final wordToShow = await _displayWord(tester);
            await _testRefocusingChangedValues(tester, wordToShow.text, wordToShow.transcription);
        });

    testWidgets('Switches focus to another text field after changes in the transcription field', 
        (tester) async {
            final wordToShow = await _displayWord(tester);

            final assistant = new WidgetAssistant(tester);
            await _showTranscriptionKeyboard(assistant, wordToShow.transcription);

            final expectedChangedTr = await _changeTranscription(tester, wordToShow.transcription);

            final refocusedFieldFinder = find.widgetWithText(TextField, wordToShow.text);
            await new WidgetAssistant(tester).tapWidget(refocusedFieldFinder);

            expect(find.widgetWithText(TextField, expectedChangedTr), findsOneWidget);

            final refocusedField = tester.widget<TextField>(refocusedFieldFinder);
            expect(refocusedField.focusNode.hasFocus, true);
        });

    testWidgets('Saves all changes to a word whereas the word text field is still focused', 
        (tester) async {
            await _testSavingChangedValue(tester, (word) => word.text);
        });
    
    testWidgets('Saves all changes to a word whereas the word translation field is still focused', 
        (tester) async {
            await _testSavingChangedValue(tester, (word) => word.translation);
        });
    
    testWidgets('Saves all changes to a word whereas the word transcription field is still focused', 
        (tester) async {
            final storage = new PackStorageMock();
            final wordToShow = await _displayWord(tester, storage: storage);

            final assistant = new WidgetAssistant(tester);
            await _showTranscriptionKeyboard(assistant, wordToShow.transcription);

            final expectedChangedTr = await _changeTranscription(tester, wordToShow.transcription);

            await assistant.pressButtonDirectly(CardEditorTester.findSaveButton());

            final changedWord = await storage.wordStorage.find(wordToShow.id);
            expect(changedWord?.transcription, expectedChangedTr);
        });
    
    testWidgets('Saves a new pack for a card', 
        (tester) async {
            final storage = new PackStorageMock();
            await _testChangingPack(storage, tester, 
                (word) async => await _fetchAnotherPack(storage, word.packId));
        });
    
    testWidgets('Saves the none pack for a card', 
        (tester) async {
            await _testChangingPack(new PackStorageMock(), tester, 
                (word) => Future.value(StoredPack.none));
        });
	
    testWidgets('Shows a warning for a card without a pack and turns off dictionaries', 
        (tester) => _testInitialDictionaryState(tester, hasPack: false));

    testWidgets('Shows a warning after nullifying a pack and turns off dictionaries', 
        (tester) => _testChangingDictionaryState(tester, nullifyPack: true));
    
    testWidgets('Turns on dictionaries and shows no warnings when a card has a pack', 
        (tester) => _testInitialDictionaryState(tester, hasPack: true));
    
    testWidgets('Turns on dictionaries and shows no warnings after choosing a pack',
        (tester) => _testChangingDictionaryState(tester, nullifyPack: false));
		
    testWidgets('Shows no popup initially when focusing on the word text field', (tester) async {
		final dicProviderMock = new DictionaryProviderMock(
			onSearchForLemmas: (text) => Randomiser.nextStringList());
		final wordText = (await _displayWordWithPack(tester, provider: dicProviderMock)).text;

		await _focusTextField(new WidgetAssistant(tester), wordText);
		AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
	});
	
	testWidgets('Shows no popup for a word without a pack', (tester) async {
		final dicProviderMock = new DictionaryProviderMock(
			onSearchForLemmas: (text) => Randomiser.nextStringList());
		final wordText = (
			await _displayWord(tester, provider: dicProviderMock, pack: StoredPack.none)
		).text;
		await new WidgetAssistant(tester).enterChangedText(wordText);

		AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
	});

	testWidgets('Shows no popup when the text field is empty or made up of spaces', (tester) async {
		final dicProviderMock = new DictionaryProviderMock(
			onSearchForLemmas: (text) => Randomiser.nextStringList());
		final wordText = (await _displayWordWithPack(tester, provider: dicProviderMock)).text;
		
		final assistant = new WidgetAssistant(tester);
		final changedText = await assistant.enterChangedText(wordText, changedText: '   ');
		AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
		
		await assistant.enterChangedText(changedText, changedText: '');
		AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
	});

	testWidgets('Shows no popup when there are no suggestions for a word', (tester) async {
		final dicProviderMock = new DictionaryProviderMock(onSearchForLemmas: (text) => []);
		final wordText = (await _displayWordWithPack(tester, provider: dicProviderMock)).text;
		await new WidgetAssistant(tester).enterChangedText(wordText);

		AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
	});

	const lemmaLimit = WordDictionary.searcheableLemmaMaxNumber;
    testWidgets('Suggests up to $lemmaLimit words to choose from a dictionary in a popup when editing the text field', 
		(tester) async { 
			final popupValues = Randomiser.nextStringList(
				minLength: lemmaLimit + 2, 
				maxLength: lemmaLimit + 5
			);
			final dicProviderMock = new DictionaryProviderMock(
				onSearchForLemmas: (text) => popupValues);
			
			final wordText = (await _displayWordWithPack(tester, provider: dicProviderMock)).text;
			await new WidgetAssistant(tester).enterChangedText(wordText);
			
			final foundTiles = tester.widgetList<ListTile>(
				AssuredFinder.findSeveral(type: ListTile, shouldFind: true))
				.map((t) => (t.title as Text).data).toList();
			expect(foundTiles.length, lemmaLimit);
			expect(popupValues.where((v) => foundTiles.contains(v)).length, lemmaLimit);
		});

	testWidgets('Closes the suggestion popup after opting for a word there and displays its chosen text', 
		(tester) async { 
			final dicProviderMock = new DictionaryProviderMock(
				onSearchForLemmas: (text) => Randomiser.nextStringList());
			final wordText = (await _displayWordWithPack(tester, provider: dicProviderMock)).text;

			final assistant = new WidgetAssistant(tester);
			await assistant.enterChangedText(wordText);
			
			final tileFinder = AssuredFinder.findSeveral(type: ListTile, shouldFind: true).first;
			final expectedText = (tester.widget<ListTile>(tileFinder).title as Text).data;

			await assistant.tapWidget(tileFinder.first);
		
			AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
			AssuredFinder.findOne(type: TextField, label: expectedText, shouldFind: true);
		});

	testWidgets('Closes the suggestion popup after the field gets unfocused', (tester) async { 
		final dicProviderMock = new DictionaryProviderMock(
			onSearchForLemmas: (text) => Randomiser.nextStringList());
		final shownWord = (await _displayWordWithPack(tester, provider: dicProviderMock));
		
		await new WidgetAssistant(tester).enterChangedText(shownWord.text);
		AssuredFinder.findSeveral(type: ListTile, shouldFind: true);

		await _focusTextField(new WidgetAssistant(tester), shownWord.translation);
		AssuredFinder.findSeveral(type: ListTile, shouldFind: false);
	});
}

Future<StoredWord> _displayWord(WidgetTester tester, { 
		DictionaryProvider provider, 
        PackStorageMock storage, StoredPack pack, 
        StoredWord wordToShow, SpeakerMock speaker,
		bool shouldHideWarningDialog = true }) async {
    storage = storage ?? new PackStorageMock();
    final wordStorage = storage.wordStorage;
    wordToShow = wordToShow ?? wordStorage.getRandom();

    await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
        childBuilder: (context) => new CardScreen(
			wordStorage: wordStorage, packStorage: storage,
			wordId: wordToShow.id, pack: pack, 
			provider: provider, 
			defaultSpeaker: speaker ?? new SpeakerMock()
		)));
    await tester.pump();
    await tester.pump(new Duration(milliseconds: 200));

    if (shouldHideWarningDialog) {
		final nonePack = StoredPack.none;
		final warningIsExpected = pack == nonePack || (pack == null && wordToShow.packId == nonePack.id);
        final emptyPackWarnDialogBtnFinder = _findWarningDialogButton(shouldFind: warningIsExpected);
        if (warningIsExpected)
            await new WidgetAssistant(tester).tapWidget(emptyPackWarnDialogBtnFinder);
    }
    
    return wordToShow;
}

Finder _findWarningDialogButton({ bool shouldFind }) {
	final dialogBtnFinder = DialogTester.findConfirmationDialogBtn();
	expect(dialogBtnFinder, AssuredFinder.matchOne(shouldFind: shouldFind));

	return dialogBtnFinder;
}
   
Future<void> _testRefocusingChangedValues(WidgetTester tester, String fieldValueToChange, 
    String fieldValueToRefocus) async {
        final expectedChangedText = 
			await new WidgetAssistant(tester).enterChangedText(fieldValueToChange);

        final refocusedFieldFinder = await _focusTextField(
			new WidgetAssistant(tester), fieldValueToRefocus);

        final initiallyFocusedFieldFinder = find.widgetWithText(TextField, expectedChangedText);
        expect(initiallyFocusedFieldFinder, findsOneWidget);

        final refocusedField = tester.widget<TextField>(refocusedFieldFinder);
        expect(refocusedField.focusNode.hasFocus, true);
    }

Future<Finder> _focusTextField(WidgetAssistant assistant, String textToFocus) async {
	final refocusedFieldFinder = find.widgetWithText(TextField, textToFocus);
	await assistant.tapWidget(refocusedFieldFinder);
	return refocusedFieldFinder;
}

Future<void> _testSavingChangedValue(WidgetTester tester, 
    String Function(StoredWord) valueToChangeGetter) async {
    final storage = new PackStorageMock();
    final wordToShow = await _displayWord(tester, storage: storage);

	final assistant = new WidgetAssistant(tester);
    final expectedChangedText = await assistant.enterChangedText(valueToChangeGetter(wordToShow));

    await assistant.tapWidget(CardEditorTester.findSaveButton());

    final changedWord = await storage.wordStorage.find(wordToShow.id);
    expect(changedWord == null, false);
    expect(valueToChangeGetter(changedWord), expectedChangedText);
}

Future<void> _showTranscriptionKeyboard(WidgetAssistant assistant, String transcription) async {
    final transcriptionFinder = find.widgetWithText(TextField, transcription);
    expect(transcriptionFinder, findsOneWidget);

    await assistant.tapWidget(transcriptionFinder);
}

Future<String> _changeTranscription(WidgetTester tester, String curTranscription) async {
    final expectedSymbols = await new CardEditorTester(tester).enterRandomTranscription();
    return curTranscription + expectedSymbols.join();
}

Future<void> _testDisplayingPackName(WidgetTester tester, [StoredPack expectedPack]) async {
    await _displayWord(tester, pack: expectedPack);

	new CardEditorTester(tester).assureRenderingPack(expectedPack);
}

Future<StoredPack> _fetchAnotherPack(PackStorageMock storage, int curPackId, 
    { canBeNonePack = false }) async => 
        (await storage.fetch()).firstWhere((p) => p.cardsNumber > 0 && p.id != curPackId && 
            (canBeNonePack || !p.isNone));

Future<void> _testChangingPack(PackStorageMock storage, WidgetTester tester, 
    Future<StoredPack> Function(StoredWord) newPackGetter) async {
    final wordToShow = await _displayWord(tester, storage: storage);

    final expectedPack = await _changePack(tester, () => newPackGetter(wordToShow));

    await new WidgetAssistant(tester).pressButtonDirectly(CardEditorTester.findSaveButton());

    final changedWord = await storage.wordStorage.find(wordToShow.id);
    expect(changedWord == null, false);
    expect(changedWord.packId, expectedPack.id);
}

Future<StoredPack> _changePack(WidgetTester tester,
	Future<StoredPack> Function() newPackGetter) async {

    StoredPack expectedPack;
    await tester.runAsync(() async => expectedPack = await newPackGetter());

	await new CardEditorTester(tester).changePack(expectedPack);

    return expectedPack;
}

void _assureTileIsTicked(Finder tileFinder) => 
    expect(find.descendant(of: tileFinder, matching: find.byIcon(Icons.check)), 
        findsOneWidget);

Future<void> _testInitialDictionaryState(WidgetTester tester, { @required bool hasPack }) 
	async {
		bool dictionaryIsActive = false;
		final client = new MockClient((request) async {
			dictionaryIsActive = true;
			return _respondWithEmptyResponse(request);
		});

		final wordToShow = await _displayWord(tester, 
			provider: new WebDictionaryProvider('', client: client),
			shouldHideWarningDialog: false,
			pack: hasPack ? PackStorageMock.generatePack(
				Randomiser.nextInt(PackStorageMock.namedPacksNumber)): StoredPack.none);
		
		await _assureWarningDialog(tester, !hasPack);

		await _inputTextAndAccept(tester, wordToShow.text);

		expect(dictionaryIsActive, hasPack);
	}

Response _respondWithEmptyResponse(Request req) => 
	HttpResponder.respondWithJson(WordDictionaryTester.isLookUpRequest(req) ? 
		{}: WordDictionaryTester.buildAcceptedLanguagesResponse());

Future<void> _assureWarningDialog(WidgetTester tester, bool shouldFind) async {
    final warningBtnFinder = _findWarningDialogButton(shouldFind: shouldFind);

    if (shouldFind)
        await new WidgetAssistant(tester).tapWidget(warningBtnFinder);
}

Future<void> _inputTextAndAccept(WidgetTester tester, String wordText) async {
	final assistant = new WidgetAssistant(tester);
    final newText = await assistant.enterChangedText(wordText);
    final textFinder = find.widgetWithText(TextField, newText);

    tester.widget<TextField>(textFinder).onEditingComplete();
    await assistant.pumpAndAnimate();
}

Future<void> _testChangingDictionaryState(WidgetTester tester, { @required bool nullifyPack }) 
	async {
		bool dictionaryIsActive = false;
		final client = new MockClient((request) async {
			if (WordDictionaryTester.isLookUpRequest(request))
				dictionaryIsActive = true;
			
			return _respondWithEmptyResponse(request);
		});
		
		final storage = new PackStorageMock();
		final wordToShow = await _displayWord(tester, storage: storage,
			provider: new WebDictionaryProvider('', client: client),
			pack: nullifyPack ? PackStorageMock.generatePack(
				Randomiser.nextInt(PackStorageMock.namedPacksNumber)): null);
		
		await _changePack(tester, () => nullifyPack ? Future.value(StoredPack.none): 
			_fetchAnotherPack(storage, wordToShow.packId));

		await _assureWarningDialog(tester, nullifyPack);

		await _inputTextAndAccept(tester, wordToShow.text);

		expect(dictionaryIsActive, !nullifyPack);
	}

Future<StoredWord> _displayWordWithPack(WidgetTester tester, { 
	DictionaryProvider provider, PackStorageMock storage, StoredWord wordToShow, 
	SpeakerMock speaker, bool shouldHideWarningDialog = true 
}) {
	storage = storage ?? new PackStorageMock();

	return _displayWord(tester, provider: provider, storage: storage, 
		pack: storage.getRandom(), 
		wordToShow: wordToShow, speaker: speaker, 
		shouldHideWarningDialog: shouldHideWarningDialog);
}
