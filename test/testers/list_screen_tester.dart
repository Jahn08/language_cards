import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utilities/test_root_widget.dart';
import '../utilities/widget_assistant.dart';

class ListScreenTester {
    final StatefulWidget Function() _screenBuilder;
    
    final String screenName;

    ListScreenTester(String screenName, StatefulWidget Function() screenBuilder):
        screenName = screenName + ' List Screen',
        _screenBuilder = screenBuilder;

    testEditorMode() {

        testWidgets(_buildDescription('switches to the editor mode and back'), (tester) async {
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

        testWidgets(_buildDescription('selects and unselects all items in the editor mode'), 
            (tester) async {
                await _pumpScreen(tester);
                
                final assistant = new WidgetAssistant(tester);
                await _activateEditorMode(assistant);

                final selectorFinder = _tryFindingEditorSelectButton(shouldFind: true);
                await assistant.tapWidget(selectorFinder);

                _assureSelectionForAllTilesInEditor(tester, true);

                await assistant.tapWidget(selectorFinder);

                _assureSelectionForAllTilesInEditor(tester);
            });

        testWidgets(_buildDescription('removes nothing when no items have been selected in the editor mode'), 
            (tester) async {
                await _pumpScreen(tester);
                
                final assistant = new WidgetAssistant(tester);
                await _activateEditorMode(assistant);

                final tilesFinder = _tryFindingSeveral(type: CheckboxListTile, shouldFind: true);

                int index = 0;
                final items = new Map.fromEntries(tester.widgetList<CheckboxListTile>(tilesFinder)
                    .map((t) => new MapEntry(index++, (t.title as Text).data)));

                final removeBtnFinder = _tryFindingEditorRemoveButton(shouldFind: true);
                await assistant.tapWidget(removeBtnFinder);

                final listTiles = tester.widgetList<CheckboxListTile>(tilesFinder).toList();
                for (final item in items.entries) {
                    final listTile = listTiles.elementAt(item.key);
                    expect((listTile.title as Text).data, item.value);
                }
            });

        testWidgets(_buildDescription('removes selected items in the editor mode'), (tester) async {
            final itemsToRemove = await _removeItemsInEditor(tester);

            _assureSelectionForAllTilesInEditor(tester);

            for (final item in itemsToRemove.entries)
                _tryFindingOne(type: Text, label: item.value);
        });

        testWidgets(_buildDescription('recovers removed items in their previous order'), (tester) async {
            final itemsToRemove = await _removeItemsInEditor(tester);

            final undoBtnFinder = _tryFindingOne(label: 'Undo', shouldFind: true);
            await new WidgetAssistant(tester).tapWidget(undoBtnFinder);

            final listTiles = tester.widgetList<CheckboxListTile>(
                _tryFindingSeveral(type: CheckboxListTile, shouldFind: true));
            for (final item in itemsToRemove.entries) {
                final listTile = listTiles.elementAt(item.key);
                
                expect(listTile.value, false);
                expect((listTile.title as Text).data, item.value);
            }
        });

        testWidgets(_buildDescription('resets selected items after quitting the editor mode'), 
            (tester) async {
                await _selectSomeItemsInEditor(tester);

                final assistant = new WidgetAssistant(tester);
                await _deactivateEditorMode(assistant);

                await _activateEditorMode(assistant);

                _assureSelectionForAllTilesInEditor(tester);
            });
    }

    String _buildDescription(String outline) => '$screenName: $outline';

    Future<void> _pumpScreen(WidgetTester tester) async {
        await tester.pumpWidget(TestRootWidget.buildAsAppHome(
            child: _screenBuilder()));
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

    Future<Map<int, String>> _removeItemsInEditor(WidgetTester tester) async {
        final itemsToRemove = await _selectSomeItemsInEditor(tester);
        
        final removeBtnFinder = _tryFindingEditorRemoveButton(shouldFind: true);
        await new WidgetAssistant(tester).tapWidget(removeBtnFinder);

        return itemsToRemove;
    }

    Future<Map<int, String>> _selectSomeItemsInEditor(WidgetTester tester) async {
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
        final itemsToRemove = new Map<int, String>();
        for (final tileFinder in tilesToSelect.entries) {
            itemsToRemove[tileFinder.key] =
                (tester.widget<CheckboxListTile>(tileFinder.value).title as Text).data;
            await assistant.tapWidget(tileFinder.value);
        }

        return itemsToRemove;
    }
}
