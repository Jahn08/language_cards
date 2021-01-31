import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/base_storage.dart';
import 'package:language_cards/src/models/stored_entity.dart';
import 'package:language_cards/src/screens/list_screen.dart';
import '../mocks/root_widget_mock.dart';
import '../utilities/assured_finder.dart';
import '../utilities/randomiser.dart';
import '../utilities/widget_assistant.dart';

class ListScreenTester<TEntity extends StoredEntity> {
	static const _searcherModeThreshold = 10;

    final ListScreen<TEntity> Function() _screenBuilder;
    
    final String screenName;

    ListScreenTester(String screenName, ListScreen<TEntity> Function() screenBuilder):
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
                    .map((t) => new MapEntry(index++, _extractTitle(tester, t.title))));

                final removeBtnFinder = _tryFindingEditorRemoveButton(shouldFind: true);
                await assistant.tapWidget(removeBtnFinder);

                final listTiles = tester.widgetList<CheckboxListTile>(tilesFinder).toList();
                for (final item in items.entries) {
                    final listTile = listTiles.elementAt(item.key);
                    expect(_extractTitle(tester, listTile.title), item.value);
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
                expect(_extractTitle(tester, listTile.title), item.value);
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

    Future<BaseStorage<TEntity>> pumpScreen(WidgetTester tester) => _pumpScreen(tester);

	Future<BaseStorage<TEntity>> _pumpScreen(WidgetTester tester, 
		[Future<void> Function(BaseStorage<TEntity>) beforePumping]) async {
		final screen = _screenBuilder();
		final storage = screen.storage;
		await beforePumping?.call(storage);

        await tester.pumpWidget(RootWidgetMock.buildAsAppHome(child: screen));
        await tester.pump(new Duration(milliseconds: 500));
		await tester.pump();

		return storage;
    }

    Future<void> activateEditorMode(WidgetAssistant assistant) =>
    	assistant.tapWidget(_tryFindingEditorButton(shouldFind: true));

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

    Future<void> deactivateEditorMode(WidgetAssistant assistant) =>
        assistant.tapWidget(_tryFindingEditorDoneButton(shouldFind: true));

    Finder _assureSelectionForAllTilesInEditor(WidgetTester tester, [bool selected = false]) {
        final tilesFinder = AssuredFinder.findSeveral(type: CheckboxListTile, shouldFind: true);
        final tiles = tester.widgetList<CheckboxListTile>(tilesFinder);
        expect(tiles.every((w) => w.value), selected);

        return tilesFinder;
    }

    String _extractTitle(WidgetTester tester, Widget title) {
        final textWidgetFinder = find.descendant(of: find.byWidget(title), 
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
                    tester.widget<CheckboxListTile>(tileFinder.value).title);
                await assistant.tapWidget(tileFinder.value);
            }

            return itemsToRemove;
        }

	testSearcherMode(TEntity Function(int) newEntityGetter) {

		testWidgets(_buildDescription('switches to the search mode and back'), 
			(tester) => testSwitchingToSearchMode(tester, newEntityGetter: newEntityGetter,
				indexGroupsGetter: (storage) => tester.runAsync(storage.groupByTextIndex)));

		testWidgets(_buildDescription('renders no search mode for a too short list'), (tester) async {
            final storage = await _pumpScreen(tester, (st) async {
				final items = await tester.runAsync(() => st.fetch());

				if (items.length > _searcherModeThreshold) {
					final idsToDelete = items.take(items.length - _searcherModeThreshold)
						.map((i) => i.id).toList();
					await tester.runAsync(() => st.delete(idsToDelete));
				}
			});

            _tryFindingSearcherEndButton(shouldFind: false);
            _tryFindingSearcherButton(shouldFind: false);

			final indexGroups = await tester.runAsync(storage.groupByTextIndex);
			assureFilterIndexes(indexGroups.keys, shouldFind: false);
        });

		testWidgets(_buildDescription('filters items by an index in the search mode and resets filtering after closing the mode'), 
			(tester) async {
				final storage = await _pumpScreenWithEnoughItems(tester, 
					newEntityGetter: newEntityGetter, searcherModeThreshold: _searcherModeThreshold);

				final indexGroups = await tester.runAsync(storage.groupByTextIndex);
			
				final assistant = new WidgetAssistant(tester);
				await activateSearcherMode(assistant);
				
				final expectedIndexGroup = Randomiser.nextElement(indexGroups.entries.toList());
				final filterIndex = expectedIndexGroup.key;
				final activeIndexFinder = _findFilterIndex(expectedIndexGroup.key, shouldFind: true);
				_assureFilterIndexActiveness(tester, filterIndex, isActive: false);
				
				await assistant.tapWidget(activeIndexFinder);
				_assureFilterIndexActiveness(tester, filterIndex, isActive: true);

                final tilesFinder = AssuredFinder.findSeveral(type: ListTile, shouldFind: true);
				final filteredTiles = tester.widgetList<ListTile>(tilesFinder);
				expect(filteredTiles.length, expectedIndexGroup.value);
				expect(filteredTiles.every((t) => 
					_extractTitle(tester, t.title).startsWith(expectedIndexGroup.key)), true);

				await deactivateSearcherMode(assistant);

				_tryFindingSearcherEndButton(shouldFind: false);
				assureFilterIndexes(indexGroups.keys, shouldFind: false);
			
				final tiles = tester.widgetList<ListTile>(tilesFinder);
				expect(tiles.length > expectedIndexGroup.value, true);
				expect(tiles.any((t) => 
					!_extractTitle(tester, t.title).startsWith(expectedIndexGroup.key)), true);
			});
	}

	Future<void> testSwitchingToSearchMode(WidgetTester tester, {
			@required TEntity Function(int) newEntityGetter, 
			@required Future<Map<String, int>> Function(BaseStorage<TEntity>) indexGroupsGetter,
			Future<int> Function() itemsLengthGetter
		}) async {
		final storage = await _pumpScreenWithEnoughItems(tester, 
			newEntityGetter: newEntityGetter, searcherModeThreshold: _searcherModeThreshold,
			itemsLengthGetter: itemsLengthGetter);

		_tryFindingSearcherEndButton(shouldFind: false);

		final indexGroups = await indexGroupsGetter(storage);
		assureFilterIndexes(indexGroups.keys, shouldFind: false);				

		final assistant = new WidgetAssistant(tester);
		await activateSearcherMode(assistant);
		
		_tryFindingSearcherButton(shouldFind: false);
		assureFilterIndexes(indexGroups.keys, shouldFind: true);
		indexGroups.keys.forEach((i) => 
			_assureFilterIndexActiveness(tester, i, isActive: false));
		
		await deactivateSearcherMode(assistant);

		_tryFindingSearcherEndButton(shouldFind: false);
		assureFilterIndexes(indexGroups.keys, shouldFind: false);
	}

	Future<BaseStorage<TEntity>> _pumpScreenWithEnoughItems(WidgetTester tester, {
		TEntity Function(int) newEntityGetter, int searcherModeThreshold,
		Future<int> Function() itemsLengthGetter 
	}) => _pumpScreen(tester, (st) async {
			int curLength;
			if (itemsLengthGetter == null)
				curLength = (await tester.runAsync(() => st.fetch())).length;
			else
				curLength = await itemsLengthGetter(); 
			
			while (curLength <= searcherModeThreshold) {
				await tester.runAsync(() => st.upsert(newEntityGetter(curLength)));
				++curLength;
			}
		});

	Finder _tryFindingSearcherEndButton({ bool shouldFind }) => 
        AssuredFinder.findOne(icon: Icons.search_off, shouldFind: shouldFind);
	
    Future<void> activateSearcherMode(WidgetAssistant assistant) =>
		assistant.tapWidget(_tryFindingSearcherButton(shouldFind: true));

    Finder _tryFindingSearcherButton({ bool shouldFind }) => 
        AssuredFinder.findOne(icon: Icons.search, shouldFind: shouldFind);

	void assureFilterIndexes(Iterable<String> indexes, { bool shouldFind }) =>
		indexes.forEach((i) => _findFilterIndex(i, shouldFind: shouldFind));

	Finder _findFilterIndex(String index, { bool shouldFind }) =>
		AssuredFinder.findOne(type: TextButton, label: index, shouldFind: shouldFind);

    Future<void> deactivateSearcherMode(WidgetAssistant assistant) =>
        assistant.tapWidget(_tryFindingSearcherEndButton(shouldFind: true));

	void _assureFilterIndexActiveness(WidgetTester tester, String index, { bool isActive }) {
		final activeIndexBoxFinder = find.ancestor(of: _findFilterIndex(index, shouldFind: true), 
			matching: find.byType(Container));
		expect(tester.widgetList<Container>(activeIndexBoxFinder)
			.singleWhere((w) => (w?.decoration as BoxDecoration)?.border != null, 
			orElse: () => null) != null, isActive ?? false);
	}
}
