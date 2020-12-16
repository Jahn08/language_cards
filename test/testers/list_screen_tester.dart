import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../mocks/root_widget_mock.dart';
import '../utilities/assured_finder.dart';
import '../utilities/widget_assistant.dart';

class ListScreenTester {
    final StatefulWidget Function() _screenBuilder;
    
    final String screenName;

    ListScreenTester(String screenName, StatefulWidget Function() screenBuilder):
        screenName = screenName + ' List Screen',
        _screenBuilder = screenBuilder;

    testEditorMode() {

        testWidgets(_buildDescription('switches to the editor mode and back'), (tester) async {
            await pumpScreen(tester);

            _tryFindingEditorDoneButton();
            _tryFindingEditorRemoveButton();
            _tryFindingEditorSelectButton();
            AssuredFinder.findSeveral(type: CheckboxListTile);
        
            tryFindingListItems(shouldFind: true);
            
            final assistant = new WidgetAssistant(tester);
            await activateEditorMode(assistant);
            
            _tryFindingEditorButton();
            tryFindingListItems();
            
            _tryFindingEditorRemoveButton(shouldFind: true);
            _tryFindingEditorSelectButton(shouldFind: true);

            _assureSelectionForAllTilesInEditor(tester);

            await deactivateEditorMode(assistant);

            _tryFindingEditorButton(shouldFind: true);
            tryFindingListItems(shouldFind: true);
            
            _tryFindingEditorDoneButton();
            _tryFindingEditorRemoveButton();
            _tryFindingEditorSelectButton();
            AssuredFinder.findSeveral(type: CheckboxListTile);
        });

        testWidgets(_buildDescription('selects and unselects all items in the editor mode'), 
            (tester) async {
                await pumpScreen(tester);
                
                final assistant = new WidgetAssistant(tester);
                await activateEditorMode(assistant);

                final selectorFinder = _tryFindingEditorSelectButton(shouldFind: true);
                await assistant.tapWidget(selectorFinder);

                _assureSelectionForAllTilesInEditor(tester, true);

                await assistant.tapWidget(selectorFinder);

                _assureSelectionForAllTilesInEditor(tester);
            });

        testWidgets(_buildDescription('removes nothing when no items have been selected in the editor mode'), 
            (tester) async {
                await pumpScreen(tester);
                
                final assistant = new WidgetAssistant(tester);
                await activateEditorMode(assistant);

                final tilesFinder = AssuredFinder.findSeveral(type: CheckboxListTile, shouldFind: true);

                int index = 0;
                final items = new Map.fromEntries(tester.widgetList<CheckboxListTile>(tilesFinder)
                    .map((t) => new MapEntry(index++, _extractTitle(tester, t))));

                final removeBtnFinder = _tryFindingEditorRemoveButton(shouldFind: true);
                await assistant.tapWidget(removeBtnFinder);

                final listTiles = tester.widgetList<CheckboxListTile>(tilesFinder).toList();
                for (final item in items.entries) {
                    final listTile = listTiles.elementAt(item.key);
                    expect(_extractTitle(tester, listTile), item.value);
                }
            });

        testWidgets(_buildDescription('removes selected items in the editor mode'), (tester) async {
            final itemsToRemove = await _removeItemsInEditor(tester);

            _assureSelectionForAllTilesInEditor(tester);

            for (final item in itemsToRemove.entries)
                AssuredFinder.findOne(type: Text, label: item.value);
        });

        testWidgets(_buildDescription('recovers removed items in their previous order'), (tester) async {
            final itemsToRemove = await _removeItemsInEditor(tester);

            final undoBtnFinder = AssuredFinder.findOne(label: 'Undo', shouldFind: true);
            await new WidgetAssistant(tester).tapWidget(undoBtnFinder);

            final listTiles = tester.widgetList<CheckboxListTile>(
                AssuredFinder.findSeveral(type: CheckboxListTile, shouldFind: true));
            for (final item in itemsToRemove.entries) {
                final listTile = listTiles.elementAt(item.key);
                
                expect(listTile.value, false);
                expect(_extractTitle(tester, listTile), item.value);
            }
        });

        testWidgets(_buildDescription('resets selected items after quitting the editor mode'), 
            (tester) async {
                await pumpScreen(tester);

                final assistant = new WidgetAssistant(tester);
                await activateEditorMode(assistant);

                await selectSomeItemsInEditor(assistant);

                await deactivateEditorMode(assistant);

                await activateEditorMode(assistant);

                _assureSelectionForAllTilesInEditor(tester);
            });
    }

    String _buildDescription(String outline) => '$screenName: $outline';

    Future<void> pumpScreen(WidgetTester tester) async {
        await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
            child: _screenBuilder()));
        await tester.pump(new Duration(milliseconds: 500));
    }

    Future<void> activateEditorMode(WidgetAssistant assistant) async {
        final editorBtnFinder = _tryFindingEditorButton(shouldFind: true);
        await assistant.tapWidget(editorBtnFinder);
    }

    Finder _tryFindingEditorButton({ bool shouldFind }) => 
        AssuredFinder.findOne(label: 'Edit', shouldFind: shouldFind);

    Finder tryFindingListItems({ bool shouldFind }) => 
        AssuredFinder.findSeveral(type: Dismissible, shouldFind: shouldFind);
    
    Finder _tryFindingEditorDoneButton({ bool shouldFind }) => 
        AssuredFinder.findOne(label: 'Done', shouldFind: shouldFind);

    Finder _tryFindingEditorRemoveButton({ bool shouldFind }) => 
        AssuredFinder.findOne(label: 'Remove', shouldFind: shouldFind);

    Finder _tryFindingEditorSelectButton({ bool shouldFind }) => 
        AssuredFinder.findOne(icon: Icons.select_all, shouldFind: shouldFind);

    Future<void> deactivateEditorMode(WidgetAssistant assistant) async {
        final editorDoneBtnFinder = _tryFindingEditorDoneButton(shouldFind: true);
        await assistant.tapWidget(editorDoneBtnFinder);
    }

    Finder _assureSelectionForAllTilesInEditor(WidgetTester tester, [bool selected = false]) {
        final tilesFinder = AssuredFinder.findSeveral(type: CheckboxListTile, shouldFind: true);
        final tiles = tester.widgetList<CheckboxListTile>(tilesFinder);
        expect(tiles.every((w) => w.value), selected);

        return tilesFinder;
    }

    String _extractTitle(WidgetTester tester, CheckboxListTile tile) {
        final textWidgetFinder = find.descendant(of: find.byWidget(tile.title), 
            matching: find.byType(Text));
        expect(textWidgetFinder, findsOneWidget);

        return (tester.widget(textWidgetFinder) as Text).data;
    }

    Future<Map<int, String>> _removeItemsInEditor(WidgetTester tester) async {
        await pumpScreen(tester);

        final assistant = new WidgetAssistant(tester);
        await activateEditorMode(assistant);
        
        final itemsToRemove = await selectSomeItemsInEditor(assistant);
        
        final removeBtnFinder = _tryFindingEditorRemoveButton(shouldFind: true);
        await assistant.tapWidget(removeBtnFinder);

        return itemsToRemove;
    }

    Future<Map<int, String>> selectSomeItemsInEditor(WidgetAssistant assistant, [int chosenIndex]) 
        async {
            final tilesFinder = AssuredFinder.findSeveral(type: CheckboxListTile, shouldFind: true);
            final tester = assistant.tester;
            final lastTileIndex = tester.widgetList(tilesFinder).length - 1;
            final middleTileIndex = chosenIndex == null || chosenIndex == 0 || 
                chosenIndex == lastTileIndex ? (lastTileIndex / 2).round(): chosenIndex;
            
            final tilesToSelect = {
                0: tilesFinder.first,
                middleTileIndex: tilesFinder.at(middleTileIndex),
                lastTileIndex: tilesFinder.last
            };
            final itemsToRemove = new Map<int, String>();
            for (final tileFinder in tilesToSelect.entries) {
                itemsToRemove[tileFinder.key] = _extractTitle(tester, 
                    tester.widget<CheckboxListTile>(tileFinder.value));
                await assistant.tapWidget(tileFinder.value);
            }

            return itemsToRemove;
        }
}
