import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/widgets/input_keyboard.dart';
import 'package:language_cards/src/widgets/phonetic_keyboard.dart';
import 'package:language_cards/src/widgets/keyboarded_field.dart';
import '../../mocks/root_widget_mock.dart';
import '../../testers/card_editor_tester.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';

void main() {
  test('Assures that there are no duplicated symbols in all phonetic keyboards',
      () {
    for (final lang in Language.values) {
      final symbols = _getEmptyKeyboard(lang).symbols;

      final countedSymbols = <String, int>{};
      symbols.forEach((s) => countedSymbols[s] = (countedSymbols[s] ?? 0) + 1);

      final duplicatedSymbols = countedSymbols.entries
          .where((e) => e.value > 1)
          .map((s) => s.key)
          .toList();
      expect(duplicatedSymbols.isEmpty, true,
          reason:
              'Duplicated symbols are found for the ${lang.present(Localizator.defaultLocalization)} keyboard: ${duplicatedSymbols.join(', ')}');
    }
  });

  testWidgets('Shows a keyboard with English phonetic symbols', (tester) async {
    final foundResult = await _createKeyboard(tester);

    _assertKeyboardIsHidden();
    await _showKeyboard(tester, foundResult);

    _getEmptyKeyboard().symbols.forEach((symbol) {
      expect(find.widgetWithText(InkWell, symbol), findsWidgets);
    });
  });

  testWidgets('Removes all symbols consecutively from the end of transcription',
      (tester) async {
    await _createKeyboard(tester, show: true);

    final expectedSymbols =
        await new CardEditorTester(tester).enterRandomTranscription();
    String input = expectedSymbols.join();

    do {
      expect(_findEditableText(input), findsOneWidget);

      await _tapIconKey(tester, Icons.backspace);
      expect(_findEditableText(input), findsNothing);

      expectedSymbols.removeLast();
      input = expectedSymbols.join();
    } while (input.isNotEmpty);

    await _tapIconKey(tester, Icons.backspace);
  });

  testWidgets('Removes a symbol in the middle of transcription',
      (tester) async {
    await _createKeyboard(tester, show: true);

    final expectedSymbols =
        await new CardEditorTester(tester).enterRandomTranscription();
    final input = expectedSymbols.join();

    final textFinder = _findEditableText(input);
    final textCtrl = tester.widget<EditableText>(textFinder);

    final doubleSymbol = expectedSymbols.firstWhere((s) => s.length > 1);
    final doubleSymbolPosition = input.indexOf(doubleSymbol);
    final offset = doubleSymbolPosition + doubleSymbol.length;
    textCtrl.controller.selection =
        new TextSelection.fromPosition(new TextPosition(offset: offset));

    await _tapIconKey(tester, Icons.backspace);

    final expectedOutput =
        input.substring(0, doubleSymbolPosition) + input.substring(offset);
    final changedTextFinder = _findEditableText(expectedOutput);
    expect(changedTextFinder, findsOneWidget);
    _assureTextPosition(
        tester, changedTextFinder, offset - doubleSymbol.length);
  });

  testWidgets('Removes a symbol partially in the middle of transcription',
      (tester) async {
    await _createKeyboard(tester, lang: Language.russian, show: true);

    final singleSymbols = <String>[
      'ə',
      'e',
      'ɛ',
      'i',
      'ɨ',
      'f',
      'g',
      'ɣ',
      'j',
      'k'
    ];
    const complexSymbol = 'ʑː';
    final expectedSymbols = await new CardEditorTester(tester)
        .enterRandomTranscription(
            symbols: singleSymbols, symbolToEnter: complexSymbol);
    final input = expectedSymbols.join();

    final textFinder = _findEditableText(input);
    final textCtrl = tester.widget<EditableText>(textFinder);

    final complexSymbolPosition = input.indexOf(complexSymbol);
    final offset = complexSymbolPosition + complexSymbol.length - 1;
    textCtrl.controller.selection =
        new TextSelection.fromPosition(new TextPosition(offset: offset));

    await _tapIconKey(tester, Icons.backspace);

    final expectedOutput =
        input.substring(0, complexSymbolPosition) + input.substring(offset);
    final changedTextFinder = _findEditableText(expectedOutput);
    expect(changedTextFinder, findsOneWidget,
        reason:
            'Expected input "$expectedOutput" is not found. Initial input: "$input", a symbol for partial deletion: "$complexSymbol"');
    _assureTextPosition(
        tester, changedTextFinder, offset - (complexSymbol.length - 1));
  });

  testWidgets(
      'Removes no previous symbols when the cursor is at the beginning of transcription',
      (tester) async {
    await _createKeyboard(tester, show: true);

    final expectedSymbols =
        await new CardEditorTester(tester).enterRandomTranscription();
    final input = expectedSymbols.join();

    final textFinder = _findEditableText(input);
    final textCtrl = tester.widget<EditableText>(textFinder);

    textCtrl.controller.selection =
        new TextSelection.fromPosition(const TextPosition(offset: 0));

    for (int i = 0; i < 3; ++i) await _tapIconKey(tester, Icons.backspace);

    final nonChangedTextFinder = _findEditableText(input);
    expect(nonChangedTextFinder, findsOneWidget);
    _assureTextPosition(tester, nonChangedTextFinder, 0);
  });

  testWidgets(
      'Enters a symbol in the middle of transcription',
      (tester) => _testEnteringSymbol(
          tester, (input) => Randomiser.nextInt(input.length - 1) + 1));

  testWidgets('Enters a symbol at the end of transcription',
      (tester) => _testEnteringSymbol(tester, (input) => input.length));

  testWidgets(
      'Removes selected symbols in the middle of transcription',
      (tester) => _testRemovingSelection(
          tester, (input) => new MapEntry(1, input.length - 2)));

  testWidgets(
      'Removes selected symbols at the beginning of transcription',
      (tester) => _testRemovingSelection(
          tester, (input) => new MapEntry(0, input.length - 2)));

  testWidgets(
      'Removes selected symbols at the end of transcription',
      (tester) => _testRemovingSelection(
          tester, (input) => new MapEntry(1, input.length)));

  testWidgets(
      'Removes everything when transcription selected wholy',
      (tester) => _testRemovingSelection(
          tester, (input) => new MapEntry(0, input.length)));

  testWidgets(
      'Enters a symbol replacing a selection in the middle of transcription',
      (tester) => _testReplacingSelectionWithSymbol(
          tester, (input) => new MapEntry(1, input.length - 2)));

  testWidgets(
      'Enters a symbol replacing a selection at the beginning of transcription',
      (tester) => _testReplacingSelectionWithSymbol(
          tester, (input) => new MapEntry(0, input.length - 2)));

  testWidgets(
      'Enters a symbol replacing a selection at the end of transcription',
      (tester) => _testReplacingSelectionWithSymbol(
          tester, (input) => new MapEntry(1, input.length)));

  testWidgets(
      'Enters a symbol replacing a selection of entire transcription',
      (tester) => _testReplacingSelectionWithSymbol(
          tester, (input) => new MapEntry(0, input.length)));

  testWidgets('Hides a keyboard by clicking on the done key', (tester) async {
    await _createKeyboard(tester, show: true);

    final expectedSymbols =
        await new CardEditorTester(tester).enterRandomTranscription();

    await _tapIconKey(tester, Icons.done);

    final input = expectedSymbols.join();
    final foundResult = _findEditableText(input);
    expect(foundResult, findsOneWidget);

    _assertKeyboardIsHidden();
    expect(
        (tester.widget(foundResult) as EditableText).focusNode.hasFocus, false);

    await tester.pump(const Duration(milliseconds: 100));
  });
}

Future<Finder> _createKeyboard(WidgetTester tester,
    {bool? show, Language? lang}) async {
  final fieldKey = new Key(Randomiser.nextString());
  final fieldWithKeyboard = new KeyboardedField(
      lang ?? Language.english, new FocusNode(), '',
      key: fieldKey);

  await tester
      .pumpWidget(RootWidgetMock.buildAsAppHome(child: fieldWithKeyboard));

  final foundResult = find.byKey(fieldKey);
  expect(foundResult, findsWidgets);

  if (show == true) await _showKeyboard(tester, foundResult);

  return foundResult;
}

Future<void> _showKeyboard(WidgetTester tester, Finder foundKeyboard) async {
  await tester.showKeyboard(foundKeyboard);
  await tester.pump();
}

void _assertKeyboardIsHidden() {
  expect(find.byType(InputKeyboard), findsNothing);
  _getEmptyKeyboard()
      .symbols
      .forEach((symbol) => expect(find.text(symbol), findsNothing));
}

Future<void> _tapIconKey(WidgetTester tester, IconData icon) async {
  final foundKey = find.widgetWithIcon(InkWell, icon);
  expect(foundKey, findsOneWidget);

  await tester.tap(foundKey);
  await tester.pump(const Duration(milliseconds: 200));
}

Finder _findEditableText(String input) => find.descendant(
    of: find.byType(EditableText), matching: find.text(input), matchRoot: true);

InputKeyboard _getEmptyKeyboard([Language? lang]) =>
    PhoneticKeyboard.getLanguageSpecific((s) => s!, lang: lang);

Future<void> _testEnteringSymbol(
    WidgetTester tester, int Function(String) positionGetter) async {
  final language = Randomiser.nextElement(Language.values);
  await _createKeyboard(tester, lang: language, show: true);

  final symbols = _getEmptyKeyboard(language).symbols;
  final cardEditorTester = new CardEditorTester(tester);
  final expectedSymbols =
      await cardEditorTester.enterRandomTranscription(symbols: symbols);
  final input = expectedSymbols.join();

  final textFinder = _findEditableText(input);
  final textCtrl = tester.widget<EditableText>(textFinder);

  final offset = positionGetter(input);
  textCtrl.controller.selection =
      new TextSelection.fromPosition(new TextPosition(offset: offset));

  final symbolToEnter = await _enterDoubleSymbol(cardEditorTester, symbols);

  final expectedOutput =
      input.substring(0, offset) + symbolToEnter + input.substring(offset);
  final changedTextFinder = _findEditableText(expectedOutput);
  expect(changedTextFinder, findsOneWidget);
  _assureTextPosition(tester, changedTextFinder, offset + symbolToEnter.length);
}

Future<String> _enterDoubleSymbol(
    CardEditorTester cardEditorTester, List<String> symbols) async {
  final doubleSymbols = symbols.where((s) => s.length > 1).toList();
  final symbolToEnter = Randomiser.nextElement(doubleSymbols);
  await cardEditorTester.tapSymbolKey(symbolToEnter);

  return symbolToEnter;
}

void _assureTextPosition(
    WidgetTester tester, Finder textFinder, int expectedPosition) {
  final selection =
      tester.widget<EditableText>(textFinder).controller.selection;
  expect(selection.isCollapsed, true);
  expect(selection.start, expectedPosition);
}

Future<void> _testRemovingSelection(WidgetTester tester,
    MapEntry<int, int> Function(String) positionGetter) async {
  await _createKeyboard(tester, show: true);

  final expectedSymbols =
      await new CardEditorTester(tester).enterRandomTranscription();
  final input = expectedSymbols.join();

  final textFinder = _findEditableText(input);
  final textCtrl = tester.widget<EditableText>(textFinder);

  final position = positionGetter(input);
  final startPosition = position.key;
  final endPosition = position.value;
  textCtrl.controller.selection =
      new TextSelection(baseOffset: startPosition, extentOffset: endPosition);

  await _tapIconKey(tester, Icons.backspace);

  final expectedOutput =
      input.substring(0, startPosition) + input.substring(endPosition);
  final changedTextFinder = _findEditableText(expectedOutput);
  expect(changedTextFinder, findsOneWidget);
  _assureTextPosition(tester, changedTextFinder, startPosition);
}

Future<void> _testReplacingSelectionWithSymbol(WidgetTester tester,
    MapEntry<int, int> Function(String) positionGetter) async {
  final language = Randomiser.nextElement(Language.values);
  await _createKeyboard(tester, lang: language, show: true);

  final symbols = _getEmptyKeyboard(language).symbols;
  final cardEditorTester = new CardEditorTester(tester);
  final expectedSymbols =
      await cardEditorTester.enterRandomTranscription(symbols: symbols);
  final input = expectedSymbols.join();

  final textFinder = _findEditableText(input);
  final textCtrl = tester.widget<EditableText>(textFinder);

  final position = positionGetter(input);
  final startPosition = position.key;
  final endPosition = position.value;
  textCtrl.controller.selection =
      new TextSelection(baseOffset: startPosition, extentOffset: endPosition);

  final symbolToEnter = await _enterDoubleSymbol(cardEditorTester, symbols);

  final expectedOutput = input.substring(0, startPosition) +
      symbolToEnter +
      input.substring(endPosition);
  final changedTextFinder = _findEditableText(expectedOutput);
  expect(changedTextFinder, findsOneWidget);
  _assureTextPosition(
      tester, changedTextFinder, startPosition + symbolToEnter.length);
}
