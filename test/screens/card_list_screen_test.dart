import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/screens/card_list_screen.dart';
import '../utilities/mock_word_storage.dart';
import '../utilities/test_root_widget.dart';
import '../utilities/widget_assistant.dart';

void main() {

    testWidgets('Switches to the editor mode and back', (tester) async {
        await _pumpScreen(tester);

        _tryFindingEditorDoneButton();
        _tryFindingEditorRemoveButton();
        _tryFindingEditorSelectButton();
        _tryFindingSeveral(type: CheckboxListTile);
    
        _tryFindingSeveral(type: Dismissible, shouldFind: true);
        
        final assistant = new WidgetAssistant(tester);
        await _activateEditorMode(assistant);
        
        _tryFindingEditorButton();
        _tryFindingSeveral(type: Dismissible);

        _tryFindingEditorRemoveButton(shouldFind: true);
        _tryFindingEditorSelectButton(shouldFind: true);

        _assureSelectionForAllTilesInEditor(tester);

        await _deactivateEditorMode(assistant);

        _tryFindingEditorButton(shouldFind: true);
        _tryFindingSeveral(type: Dismissible, shouldFind: true);

        _tryFindingEditorDoneButton();
        _tryFindingEditorRemoveButton();
        _tryFindingEditorSelectButton();
        _tryFindingSeveral(type: CheckboxListTile);
    });

    testWidgets('Selects and unselects all words in the editor mode', (tester) async {
        await _pumpScreen(tester);
        
        final assistant = new WidgetAssistant(tester);
        await _activateEditorMode(assistant);

        final selectorFinder = _tryFindingEditorSelectButton(shouldFind: true);
        await assistant.tapWidget(selectorFinder);

        _assureSelectionForAllTilesInEditor(tester, true);

        await assistant.tapWidget(selectorFinder);

        _assureSelectionForAllTilesInEditor(tester);
    });

    testWidgets('Removes nothing when no words have been selected in the editor mode', (tester) async {
        await _pumpScreen(tester);
        
        final assistant = new WidgetAssistant(tester);
        await _activateEditorMode(assistant);

        final tilesFinder = _tryFindingSeveral(type: CheckboxListTile, shouldFind: true);

        int index = 0;
        final words = new Map.fromEntries(tester.widgetList<CheckboxListTile>(tilesFinder)
            .map((t) => new MapEntry(index++, (t.title as Text).data)));

        final removeBtnFinder = _tryFindingEditorRemoveButton(shouldFind: true);
        await assistant.tapWidget(removeBtnFinder);

        final listTiles = tester.widgetList<CheckboxListTile>(tilesFinder).toList();
        for (final word in words.entries) {
            final listTile = listTiles.elementAt(word.key);
            expect((listTile.title as Text).data, word.value);
        }
    });

    testWidgets('Removes selected words in the editor mode', (tester) async {
        final wordsToRemove = await _removeWordsInEditor(tester);

        _assureSelectionForAllTilesInEditor(tester);

        for (final word in wordsToRemove.entries)
            _tryFindingOne(type: Text, label: word.value);
    });

    testWidgets('Recovers removed words in their previous order', (tester) async {
        final wordsToRemove = await _removeWordsInEditor(tester);

        final undoBtnFinder = _tryFindingOne(label: 'Undo', shouldFind: true);
        await new WidgetAssistant(tester).tapWidget(undoBtnFinder);

        final listTiles = tester.widgetList<CheckboxListTile>(
            _tryFindingSeveral(type: CheckboxListTile, shouldFind: true));
        for (final word in wordsToRemove.entries) {
            final listTile = listTiles.elementAt(word.key);
            
            expect(listTile.value, false);
            expect((listTile.title as Text).data, word.value);
        }
    });

    testWidgets('Resets selected words after quitting the editor mode', (tester) async {
        await _selectSomeWordsInEditor(tester);

        final assistant = new WidgetAssistant(tester);
        await _deactivateEditorMode(assistant);

        await _activateEditorMode(assistant);

        _assureSelectionForAllTilesInEditor(tester);
    });
}

Future<void> _pumpScreen(WidgetTester tester, [MockWordStorage storage]) async {
    storage = storage ?? new MockWordStorage();
    await tester.pumpWidget(TestRootWidget.buildAsAppHome(
        child: new CardListScreen(storage)));
    await tester.pumpAndSettle(new Duration(milliseconds: 900));
}

Future<void> _activateEditorMode(WidgetAssistant assistant) async {
    final editorBtnFinder = _tryFindingEditorButton(shouldFind: true);
    await assistant.tapWidget(editorBtnFinder);
}

Finder _tryFindingEditorButton({ bool shouldFind }) => 
    _tryFindingOne(label: 'Edit', shouldFind: shouldFind);

Finder _tryFindingOne({ String label, IconData icon, Type type, bool shouldFind }) => 
    _tryFinding(expectSeveral: false, icon: icon, label: label, type: type, shouldFind: shouldFind);

Finder _tryFinding({ String label, IconData icon, Type type,
    bool shouldFind, bool expectSeveral }) {
    
    Finder finder;
    if (label != null && type != null)
        finder = find.widgetWithText(type, label);
    if (label != null)
        finder = find.text(label);
    else if(icon != null)
        finder = find.byIcon(icon);
    else
        finder = find.byType(type);

    expect(finder, (shouldFind ?? false) ? 
        ((expectSeveral ?? false) ? findsWidgets : findsOneWidget): findsNothing);
    return finder;
}

Finder _tryFindingSeveral({ String label, Type type, bool shouldFind }) =>
    _tryFinding(expectSeveral: true, label: label, type: type, shouldFind: shouldFind);

Finder _tryFindingEditorDoneButton({ bool shouldFind }) => 
    _tryFindingOne(label: 'Done', shouldFind: shouldFind);

Finder _tryFindingEditorRemoveButton({ bool shouldFind }) => 
    _tryFindingOne(label: 'Remove', shouldFind: shouldFind);

Finder _tryFindingEditorSelectButton({ bool shouldFind }) => 
    _tryFindingOne(icon: Icons.select_all, shouldFind: shouldFind);

Future<void> _deactivateEditorMode(WidgetAssistant assistant) async {
    final editorDoneBtnFinder =_tryFindingEditorDoneButton(shouldFind: true);
    await assistant.tapWidget(editorDoneBtnFinder);
}

Finder _assureSelectionForAllTilesInEditor(WidgetTester tester, [bool selected = false]) {
    final tilesFinder = _tryFindingSeveral(type: CheckboxListTile, shouldFind: true);
    expect(tester.widgetList<CheckboxListTile>(tilesFinder).every((w) => w.value), selected);

    return tilesFinder;
}

Future<Map<int, String>> _removeWordsInEditor(WidgetTester tester) async {
    final wordsToRemove = await _selectSomeWordsInEditor(tester);
    
    final removeBtnFinder = _tryFindingEditorRemoveButton(shouldFind: true);
    await new WidgetAssistant(tester).tapWidget(removeBtnFinder);

    return wordsToRemove;
}

Future<Map<int, String>> _selectSomeWordsInEditor(WidgetTester tester) async {
    await _pumpScreen(tester);

    final assistant = new WidgetAssistant(tester);
    await _activateEditorMode(assistant);

    final tilesFinder = _tryFindingSeveral(type: CheckboxListTile, shouldFind: true);
    final tilesFinderLength = tester.widgetList(tilesFinder).length - 1;
    final middleTileIndex = (tilesFinderLength / 2).round();
    
    final tilesToSelect = {
        0: tilesFinder.first,
        middleTileIndex: tilesFinder.at(middleTileIndex),
        tilesFinderLength: tilesFinder.last
    };
    final wordsToRemove = new Map<int, String>();
    for (final tileFinder in tilesToSelect.entries) {
        wordsToRemove[tileFinder.key] =
            (tester.widget<CheckboxListTile>(tileFinder.value).title as Text).data;
        await assistant.tapWidget(tileFinder.value);
    }

    return wordsToRemove;
}
