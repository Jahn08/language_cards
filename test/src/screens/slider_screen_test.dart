import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/screens/slider_screen.dart';
import '../../mocks/root_widget_mock.dart';
import '../../mocks/asset_bundle_mock.dart';
import '../../testers/dialog_tester.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/widget_assistant.dart';

main() {

	testWidgets('Goes forward through all the available slides and then backward again', 
		(tester) async {
			final loadedSlides = <String>[];
			await _pumpScreen(tester, 
				(key, data) {
					if (data != null && key.endsWith('jpg'))
						loadedSlides.add(key);
				});
			
			final assistant = new WidgetAssistant(tester);
			await _closeDialog(assistant);
		
			final leftArrowFinder = _findIconButton(Icons.chevron_left_outlined);
			expect(_isButtonEnabled(tester, leftArrowFinder), false);
			
			final rightArrowFinder = _findRightArrowBtn();
			int pageIndex = 1;
			_assurePageIndicator(tester, pageIndex);

			do {
				await assistant.tapWidget(rightArrowFinder);
				_assurePageIndicator(tester, ++pageIndex);

				await _closeDialog(assistant);
			} while(_isButtonEnabled(tester, rightArrowFinder));

			expect(loadedSlides.length, pageIndex);

			do {
				await assistant.tapWidget(leftArrowFinder);
				_assurePageIndicator(tester, --pageIndex);

				await _closeDialog(assistant);
			} while(_isButtonEnabled(tester, leftArrowFinder));

			expect(pageIndex, 1);
		});
		
	testWidgets('Displays a helping dialog by clicking on the information icon', (tester) async {
		await _pumpScreen(tester);

		final firstSlideInitialInfo = _extractDialogData(tester);

		final assistant = new WidgetAssistant(tester);
		await _closeDialog(assistant);
	
		final firstSlideInfo = await _assureInfoDialogRendering(assistant);
		expect(firstSlideInfo.key, firstSlideInitialInfo.key);
		expect(firstSlideInfo.value, firstSlideInitialInfo.value);

		final rightArrowFinder = _findRightArrowBtn();
		await assistant.tapWidget(rightArrowFinder);

		final nextSlideInitialInfo = _extractDialogData(tester);
		await _closeDialog(assistant);

		final nextSlideInfo = await _assureInfoDialogRendering(assistant);
		expect(nextSlideInfo.key, nextSlideInitialInfo.key);
		expect(nextSlideInfo.value, nextSlideInitialInfo.value);
		
		expect(firstSlideInfo.key == nextSlideInfo.key, false);
		expect(firstSlideInfo.value == nextSlideInfo.value, false);
	});
}

Future<void> _pumpScreen(WidgetTester tester, [Function(String, ByteData) onAssetLoaded]) async {
	await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
		child: new DefaultAssetBundle(
			bundle: new AssetBundleMock(
				onAssetLoaded: onAssetLoaded
			), 
			child: new CardHelpScreen()
		)
	));
	await tester.pump();
}

Finder _findIconButton(IconData icon) {
	final finder = find.ancestor(of: find.byIcon(icon), matching: find.byType(IconButton));
	expect(finder, findsOneWidget);
	return finder;
}

Finder _findRightArrowBtn() => _findIconButton(Icons.chevron_right_outlined);

bool _isButtonEnabled(WidgetTester tester, Finder btnFinder) => 
	tester.widget<IconButton>(btnFinder).onPressed != null;

Future<void> _closeDialog(WidgetAssistant assistant) async {
	final dialogBtnFinder = DialogTester.findConfirmationDialogBtn();
	expect(dialogBtnFinder, findsOneWidget);

	await assistant.tapWidget(dialogBtnFinder);
}

void _assurePageIndicator(WidgetTester tester, int pageIndex) {
	final barTitleFinder = find.descendant(
		of: find.byType(AppBar), matching: find.byType(Text));
	final pageIndicator = ' $pageIndex ';
	tester.widgetList<Text>(barTitleFinder)
		.singleWhere((t) => t.data.contains(pageIndicator));
}

Future<MapEntry<String, String>> _assureInfoDialogRendering(WidgetAssistant assistant) async {
	final infoBtnFinder = AssuredFinder.findOne(icon: Icons.info, shouldFind: true);
	final timesToTap = Randomiser.nextInt(3) + 2;
	
	String initialTitle;
	String initialContent;
	for (int i = 0; i < timesToTap; ++i) {
		await assistant.tapWidget(infoBtnFinder);

		final dialogData = _extractDialogData(assistant.tester);

		final title = dialogData.key;
		if (initialTitle == null)
			initialTitle = title;
		else
			expect(title, initialTitle);

		final content = dialogData.value;
		if (initialContent == null)
			initialContent = content;
		else
			expect(content, initialContent);

		await _closeDialog(assistant);
	}

	return new MapEntry(initialTitle, initialContent);
}

MapEntry<String, String> _extractDialogData(WidgetTester tester) {
	final dialog = DialogTester.findConfirmationDialog(tester);
	return new MapEntry((dialog.title as Text).data, (dialog.content as Text).data);
}
