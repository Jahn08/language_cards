import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/widgets/english_phonetic_keyboard.dart';
import 'package:language_cards/src/widgets/speaker_button.dart';
import '../utilities/assured_finder.dart';
import '../utilities/randomiser.dart';
import '../utilities/widget_assistant.dart';

class CardEditorTester {

	WidgetTester tester;

	CardEditorTester(this.tester);

	void assureRenderingCardFields(StoredWord card) {
		AssuredFinder.findOne(type: TextField, label: card.text, shouldFind: true);
		AssuredFinder.findOne(type: TextField, label: card.translation, shouldFind: true);
		AssuredFinder.findOne(type: TextField, label: card.transcription, shouldFind: true);

		final posField = tester.widget<DropdownButton<String>>(
			find.byType(AssuredFinder.typify<DropdownButton<String>>()));
		expect(posField.value, card.partOfSpeech.valueList.first);
	}

	void assureRenderingPack([StoredPack pack]) {
		final packBtnFinder = findPackButton();
		final packLabelFinder = find.descendant(of: packBtnFinder, matching: find.byType(Text));
		expect(packLabelFinder, findsOneWidget);
		
		final packLabel = tester.widget<Text>(packLabelFinder);
		expect(packLabel.data.endsWith(pack?.name ?? StoredPack.noneName), true);
	}

	static Finder findPackButton() => 
		AssuredFinder.findFlatButtonByIcon(Icons.folder_open, shouldFind: true);

	static Finder findSpeakerButton({ bool shouldFind }) => 
		AssuredFinder.findOne(type: SpeakerButton, shouldFind: shouldFind);
	
	void assureNonZeroStudyProgress(int studyProgress) {
		final progressBtnFinder = findStudyProgressButton(shouldFind: true);
		final progressLabelFinder = find.descendant(of: progressBtnFinder, 
			matching: find.byType(Text));
		expect(progressLabelFinder, findsOneWidget);
		expect(tester.widget<Text>(progressLabelFinder)
			.data.contains('$studyProgress%'), true);
	}

	static Finder findStudyProgressButton({ bool shouldFind }) => 
		AssuredFinder.findFlatButtonByIcon(Icons.restore, shouldFind: shouldFind);

	static Finder findSaveButton() => 
		AssuredFinder.findOne(type: ElevatedButton, label: 'Save', shouldFind: true);

	Future<void> changePack(StoredPack newPack) async {
		final assistant = new WidgetAssistant(tester);
		await assistant.tapWidget(findPackButton());

		final packTileFinder = findListTileByTitle(newPack.name);
		await assistant.tapWidget(packTileFinder);
	}

	static Finder findListTileByTitle(String title) {
		final tileFinder = find.ancestor(of: find.text(title), 
			matching: find.byType(ListTile));
		expect(tileFinder, findsOneWidget); 

		return tileFinder;
	}

	Future<List<String>> enterRandomTranscription() async {
        const symbols = EnglishPhoneticKeyboard.phonetic_symbols;
        final expectedSymbols = [Randomiser.nextElement(symbols),
            Randomiser.nextElement(symbols), Randomiser.nextElement(symbols)];

		final assistant = new WidgetAssistant(tester);
        for (final symbol in expectedSymbols)
            await _tapSymbolKey(symbol, assistant);

        return expectedSymbols;
    }

    Future<void> _tapSymbolKey(String symbol, WidgetAssistant assistant) async {
        final foundKey = find.widgetWithText(InkWell, symbol);
        expect(foundKey, findsOneWidget);

		await assistant.tapWidget(foundKey);
    }
}
