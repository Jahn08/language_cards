import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/base_storage.dart';
import 'package:language_cards/src/models/stored_entity.dart';
import 'package:language_cards/src/screens/list_screen.dart';
import 'dialog_tester.dart';
import '../mocks/root_widget_mock.dart';
import '../utilities/assured_finder.dart';
import '../utilities/localizator.dart';
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

				await _selectAll(assistant);
                _assureSelectionForAllTilesInEditor(tester, true);

				await _selectAll(assistant);
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
            final itemsToRemove = await _testRemovingItemsInEditor(tester, selectSomeItemsInEditor);

            _assureSelectionForAllTilesInEditor(tester);

            for (final item in itemsToRemove.entries)
                AssuredFinder.findOne(type: ListTile, label: item.value);
        });

        testWidgets(_buildDescription('recovers removed items in their previous order'), (tester) async {
            final itemsToRemove = await _testRemovingItemsInEditor(tester, selectSomeItemsInEditor);

            final assistnat = new WidgetAssistant(tester);
			await _undoRemoval(assistnat);
            
			await _assureRecoveredItems(assistnat, itemsToRemove);
        });

		testWidgets(_buildDescription('recovers all removed items in their previous order'), (tester) async {
            final itemsToRemove = await _testRemovingItemsInEditor(tester, (assistant) async {
				await deactivateEditorMode(assistant);
				
				int index = 0;
				final itemsToCheck = new Map.fromEntries(tester.widgetList<ListTile>(
					AssuredFinder.findSeveral(type: ListTile, shouldFind: true)
				).map((t) => new MapEntry(index++, _extractTitle(tester, t.title))));

				await activateEditorMode(assistant);
				await _selectAll(assistant);

				return itemsToCheck;
			});

            final assistant = new WidgetAssistant(tester);
			await _undoRemoval(assistant);
            
			await _assureRecoveredItems(assistant, itemsToRemove);
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

	Future<BaseStorage<TEntity>> pumpScreen(WidgetTester tester, 
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
        AssuredFinder.findOne(icon: Icons.edit, shouldFind: shouldFind);

    Finder tryFindingListItems({ bool shouldFind }) => 
        AssuredFinder.findSeveral(type: Dismissible, shouldFind: shouldFind);
    
    Finder _tryFindingEditorDoneButton({ bool shouldFind }) => 
        AssuredFinder.findOne(icon: Icons.edit_off, shouldFind: shouldFind);

    Finder _tryFindingEditorRemoveButton({ bool shouldFind }) => 
        AssuredFinder.findOne(icon: Icons.delete, shouldFind: shouldFind);

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

    Future<Map<int, String>> _testRemovingItemsInEditor(WidgetTester tester,
		Future<Map<int, String>> Function(WidgetAssistant) itemsSelector) async {
        await pumpScreen(tester);

        final assistant = new WidgetAssistant(tester);
        await activateEditorMode(assistant);
        
		final itemsToRemove = await itemsSelector(assistant);
        
        final removeBtnFinder = _tryFindingEditorRemoveButton(shouldFind: true);
        await assistant.tapWidget(removeBtnFinder);

		await _confirmRemovalIfNecessary(assistant);

        return itemsToRemove;
    }

	Future<void> _confirmRemovalIfNecessary(WidgetAssistant assistant, { 
		bool shouldCancel = false, bool shouldAccept = false, bool shouldNotWarn = false 
	}) async {
		final btnLabel = shouldCancel ? 
			Localizator.defaultLocalization.cancellableDialogCancellationButtonLabel: 'Remove';
		final dialogBtnFinder = DialogTester.findConfirmationDialogBtn(btnLabel);

		if (shouldNotWarn)
			expect(dialogBtnFinder, findsNothing);
		else if (shouldCancel || shouldAccept)
			expect(dialogBtnFinder, findsOneWidget);

		if (findsOneWidget.matches(dialogBtnFinder, {}))
			await assistant.tapWidget(dialogBtnFinder);
	}

	Future<void> _assureRecoveredItems(
		WidgetAssistant assistant, Map<int, String> expectedItems) async {
		final tester = assistant.tester;
		final checkTiles = tester.widgetList<CheckboxListTile>(
			AssuredFinder.findSeveral(type: CheckboxListTile, shouldFind: true));
		expect(checkTiles.every((t) => !t.value), true);

		await deactivateEditorMode(assistant);

		final listTiles = tester.widgetList<ListTile>(
			AssuredFinder.findSeveral(type: ListTile, shouldFind: true));
		for (final item in expectedItems.entries) {
			final listTile = listTiles.elementAt(item.key);
			expect(_extractTitle(tester, listTile.title), item.value);
		}
	}
	
	Future<void> _undoRemoval(WidgetAssistant assistnat) async {
		final undoBtnFinder = AssuredFinder.findOne(label: 'Undo', shouldFind: true);
		await assistnat.tapWidget(undoBtnFinder);
	}

    Future<Map<int, String>> selectSomeItemsInEditor(WidgetAssistant assistant, [int chosenIndex]) 
        async {
            final tilesFinder = AssuredFinder.findSeveral(type: CheckboxListTile, shouldFind: true);
            
			final tester = assistant.tester;
			final removableItemsLength = tester.widgetList(tilesFinder).length;
			final lastTileIndex = removableItemsLength - 1;
            
			final overallLength = tester.widgetList(find.byType(ListTile)).length;
			final indexLag = overallLength - removableItemsLength;
            final middleTileIndex = chosenIndex == null || chosenIndex == 0 || 
                chosenIndex == lastTileIndex ? (lastTileIndex / 2).round(): chosenIndex;
			
			final tileIndexesToSelect = [0, middleTileIndex, lastTileIndex];
            final itemsToRemove = new Map<int, String>();
            for (final indexToSelect in tileIndexesToSelect) {
				final index = indexToSelect + indexLag;
				if (itemsToRemove.containsKey(index))
					continue;
				
				final finder = tilesFinder.at(indexToSelect);
				itemsToRemove[index] = _extractTitle(tester, 
                    tester.widget<CheckboxListTile>(finder).title);
                await assistant.tapWidget(finder);
            }

            return itemsToRemove;
        }

	testDismissingItems() {

		final forEachDismissible = (int itemsNumber, Future<void> Function(Finder) processor) async {
			final dismissibleFinders = tryFindingListItems(shouldFind: true);
			for (int i = 0; i < itemsNumber; ++i)
				await processor(find.ancestor(of: find.byType(ListTile), 
					matching: dismissibleFinders).last);
		};

		final assertItemsRemoval = 
			(WidgetAssistant assistant, List<String> removedTitles, BaseStorage<TEntity> storage) async {
				await assistant.pumpAndAnimate(500);

				for (final title in removedTitles) {
					AssuredFinder.findOne(type: ListTile, label: title);

					final storedItems = await assistant.tester.runAsync(
						() => storage.fetch(textFilter: title));
					expect(storedItems.isEmpty, true);
				}
			};

        testWidgets(_buildDescription('removes items by dismissing'), (tester) async {
			final storage = await pumpScreen(tester);

			final assistant = new WidgetAssistant(tester);

			final removedTitles = <String>[];
			await forEachDismissible(2, (dismissible) async {
				final title = await _removeByDismissing(assistant, dismissible);
			
				await assistant.pumpAndAnimate(2000);
				removedTitles.add(title);			
			});

			await assertItemsRemoval(assistant, removedTitles, storage);
		});

        testWidgets(_buildDescription('recovers an item from some of dismissed ones'), 
			(tester) async { 
				final storage = await pumpScreen(tester);

				final assistant = new WidgetAssistant(tester);

				final removedTitles = <String>[];
				String recoveredTitle;
				await forEachDismissible(3, (dismissible) async {
					final title = await _removeByDismissing(assistant, dismissible);
					
					if (removedTitles.isEmpty || recoveredTitle != null) {
						removedTitles.add(title);

						await assistant.pumpAndAnimate(2000);
					}
					else {
						recoveredTitle = title;
						await _undoRemoval(new WidgetAssistant(tester));

						AssuredFinder.findOne(type: ListTile, label: recoveredTitle, shouldFind: true);
					}
				});

				await assertItemsRemoval(assistant, removedTitles, storage);
			});
	}

	Future<String> _removeByDismissing(WidgetAssistant assistant, Finder dismissible) async {
		final tester = assistant.tester;
		final listTile = tester.widget<ListTile>(
			find.descendant(of: dismissible, matching: find.byType(ListTile)));
		final removedTitle = _extractTitle(tester, listTile.title);

		await assistant.swipeWidgetLeft(dismissible);

		await _confirmRemovalIfNecessary(assistant);

		return removedTitle;
	}

	testSearchMode(TEntity Function(int) newEntityGetter) {

		testWidgets(_buildDescription('switches to the search mode and back'), 
			(tester) => testSwitchingToSearchMode(tester, newEntityGetter: newEntityGetter));

		testWidgets(_buildDescription('renders no search mode for a too short list'), (tester) async {
            final storage = await pumpScreen(tester, (st) async {
				final items = await tester.runAsync(() => st.fetch());

				if (items.length > _searcherModeThreshold) {
					final idsToDelete = items.take(items.length - _searcherModeThreshold)
						.map((i) => i.id).toList();
					await tester.runAsync(() => st.delete(idsToDelete));
				}
			});

            findSearcherEndButton(shouldFind: false);
            _findSearcherButton(shouldFind: false);

			final indexGroups = await tester.runAsync(storage.groupByTextIndex);
			assureFilterIndexes(indexGroups.keys, shouldFind: false);
        });

		testWidgets(_buildDescription('filters items by an index in the search mode and resets filtering after closing the mode'), 
			(tester) async {
				final storage = await _pumpScreenWithEnoughItems(tester, 
					newEntityGetter: newEntityGetter, searcherModeThreshold: _searcherModeThreshold);

				final indexGroups = await _getIndexGroups(tester, storage);
			
				final assistant = new WidgetAssistant(tester);
				await _activateSearchMode(assistant);

				final filterGroup = indexGroups.first;
				final filterIndex = filterGroup.key;
				await chooseFilterIndex(assistant, filterIndex);
				assureFilterIndexActiveness(tester, filterIndex, isActive: true);

                final tilesFinder = AssuredFinder.findSeveral(type: ListTile, shouldFind: true);
				final filteredTiles = tester.widgetList<ListTile>(tilesFinder);
				final filterLength = filterGroup.value;
				expect(filteredTiles.length, filterLength);
				expect(filteredTiles.every((t) => 
					_extractTitle(tester, t.title).startsWith(filterIndex)), true);

				await deactivateSearcherMode(assistant);

				findSearcherEndButton(shouldFind: false);
				assureFilterIndexes(indexGroups.map((g) => g.key), shouldFind: false);
			
				final tiles = tester.widgetList<ListTile>(tilesFinder);
				expect(tiles.length > filterLength, true);
				expect(tiles.any((t) => 
					!_extractTitle(tester, t.title).startsWith(filterIndex)), true);
			});
			
		testWidgets(_buildDescription('deletes a previously acitve index filter after clicking on another when the search mode is active'), 
			(tester) async {
				final storage = await _pumpScreenWithEnoughItems(tester, 
					newEntityGetter: newEntityGetter, searcherModeThreshold: _searcherModeThreshold);

				final assistant = new WidgetAssistant(tester);
				await _activateSearchMode(assistant);
				
				final indexGroups = await _getIndexGroups(tester, storage);
				final filterGroup = indexGroups.first;
				final filterIndex = filterGroup.key;
				await chooseFilterIndex(assistant, filterIndex);

				await activateEditorMode(assistant);
				await _deleteAllItemsInEditor(assistant);

				assureFilterIndexActiveness(tester, filterIndex, isActive: true);

				indexGroups.remove(filterGroup);
				final newFilterGroup = indexGroups.first;
				final newFilterIndex = newFilterGroup.key;
				await chooseFilterIndex(assistant, newFilterIndex);

				assureFilterIndexActiveness(tester, newFilterIndex, isActive: true);
				_findFilterIndex(filterIndex, shouldFind: false);
			
				assureFilterIndexes(indexGroups.map((g) => g.key).toList(), shouldFind: true);
			});

		testWidgets(_buildDescription('deletes an index filter when its items are deleted and the search mode is active'), 
			(tester) async {
				final storage = await _pumpScreenWithEnoughItems(tester, 
					newEntityGetter: newEntityGetter, searcherModeThreshold: _searcherModeThreshold);

				final assistant = new WidgetAssistant(tester);
				await _activateSearchMode(assistant);
				
				final indexGroups = await _getIndexGroups(tester, storage);
				final filterGroupToDelete = indexGroups.first;
				final filterIndexToDelete = filterGroupToDelete.key;

				await activateEditorMode(assistant);
				final titlesToDelete = (await tester.runAsync(() => 
					storage.fetch(textFilter: filterIndexToDelete))).map((i) => i.textData).toList();
				await selectItemsInEditor(assistant, titlesToDelete);
				await deleteSelectedItems(assistant);

				_findFilterIndex(filterIndexToDelete, shouldFind: false);
			});

		testWidgets(_buildDescription('deletes an index filter when its items are deleted with the search mode turned off'), 
			(tester) async {
				final storage = await _pumpScreenWithEnoughItems(tester, 
					newEntityGetter: newEntityGetter, searcherModeThreshold: _searcherModeThreshold);

				final assistant = new WidgetAssistant(tester);
				
				final indexGroups = await _getIndexGroups(tester, storage);
				final filterGroupToDelete = indexGroups.first;
				final filterIndexToDelete = filterGroupToDelete.key;

				await activateEditorMode(assistant);
				final titlesToDelete = (await tester.runAsync(() => 
					storage.fetch(textFilter: filterIndexToDelete))).map((i) => i.textData).toList();
				await selectItemsInEditor(assistant, titlesToDelete);
				await deleteSelectedItems(assistant);

				await _activateSearchMode(assistant);
				_findFilterIndex(filterIndexToDelete, shouldFind: false);
			});

		testWidgets(_buildDescription('keeps an index filter when it still has items left after deletion in the active search mode'), 
			(tester) async {
				final storage = await _pumpScreenWithEnoughItems(tester, 
					newEntityGetter: newEntityGetter, searcherModeThreshold: _searcherModeThreshold);

				final assistant = new WidgetAssistant(tester);
				await _activateSearchMode(assistant);
				
				final indexGroups = await _getIndexGroups(tester, storage);
				final filterGroupToDelete = indexGroups.firstWhere((e) => e.value > 1);
				final filterIndexToDelete = filterGroupToDelete.key;

				await activateEditorMode(assistant);
				final titlesToDelete = (await tester.runAsync(() => 
					storage.fetch(textFilter: filterIndexToDelete)))
					.take(1).map((i) => i.textData).toList();
				await selectItemsInEditor(assistant, titlesToDelete);
				await deleteSelectedItems(assistant);

				_findFilterIndex(filterIndexToDelete, shouldFind: true);
			});

		testWidgets(_buildDescription('hides the search mode button when the mode is inactive, and the list has got too short'), 
			(tester) async {
				final storage = await _pumpScreenWithEnoughItems(tester, 
					newEntityGetter: newEntityGetter, searcherModeThreshold: _searcherModeThreshold);
				await _deleteItemsUntilSearchIsUnavailable(new WidgetAssistant(tester), storage);

				_findSearcherButton(shouldFind: false);
			});

		testWidgets(_buildDescription('quits the search mode and hides its button when the list has got too short, and there is no active filter'), 
			(tester) async {
				final storage = await _pumpScreenWithEnoughItems(tester, 
					newEntityGetter: newEntityGetter, searcherModeThreshold: _searcherModeThreshold);

				final assistant = new WidgetAssistant(tester);
				await _activateSearchMode(assistant);
				await _deleteItemsUntilSearchIsUnavailable(assistant, storage);

				_findSearcherButton(shouldFind: false);
				findSearcherEndButton(shouldFind: false);
			});

		testWidgets(_buildDescription('hides the search mode button after deactivating the mode when the list has got too short, and there is an active filter index'), 
			(tester) async {
				final storage = await _pumpScreenWithEnoughItems(tester, 
					newEntityGetter: newEntityGetter, searcherModeThreshold: _searcherModeThreshold);

				final assistant = new WidgetAssistant(tester);
				await activateEditorMode(assistant);
				await _activateSearchMode(assistant);

				final indexGroups = await _getIndexGroups(tester, storage);
				int overallLength = indexGroups.fold<int>(0, (res, e) => res + e.value);
				for (final gr in indexGroups) {
					await chooseFilterIndex(assistant, gr.key);
					await _deleteAllItemsInEditor(assistant);

					overallLength -= gr.value;
					if (overallLength < _searcherModeThreshold)
						break;
				}

				await deactivateSearcherMode(assistant);
				_findSearcherButton(shouldFind: false);
			});
	}

	Future<List<MapEntry<String, int>>> _getIndexGroups(
		WidgetTester tester, BaseStorage<TEntity> storage
	) async => ((await tester.runAsync(storage.groupByTextIndex)).entries.toList()
		..sort((a, b) => a.key.compareTo(b.key))).toList();

	Future<List<String>> testSwitchingToSearchMode(WidgetTester tester, {
		@required TEntity Function(int) newEntityGetter, 
		Future<Map<String, int>> Function(BaseStorage<TEntity>) indexGroupsGetter,
		Future<int> Function() itemsLengthGetter,
		bool shouldKeepInSearchMode
	}) async {
		final storage = await _pumpScreenWithEnoughItems(tester, 
			newEntityGetter: newEntityGetter, searcherModeThreshold: _searcherModeThreshold,
			itemsLengthGetter: itemsLengthGetter);

		findSearcherEndButton(shouldFind: false);

		Iterable<MapEntry<String, int>> indexGroups;
		if (indexGroupsGetter == null)
			indexGroups = (await _getIndexGroups(tester, storage)); 
		else
			indexGroups = (await indexGroupsGetter(storage)).entries; 

		final indexes = indexGroups.map((g) => g.key).toList();
		assureFilterIndexes(indexes, shouldFind: false);				

		final assistant = new WidgetAssistant(tester);
		await _activateSearchMode(assistant);
		
		_findSearcherButton(shouldFind: false);
		assureFilterIndexes(indexes, shouldFind: true);
		indexes.forEach((i) => 
			assureFilterIndexActiveness(tester, i, isActive: false));

		if (!(shouldKeepInSearchMode ?? false)) {
			await deactivateSearcherMode(assistant);
	
			findSearcherEndButton(shouldFind: false);
			assureFilterIndexes(indexes, shouldFind: false);
		}
		
		return indexes;
	}

	Future<BaseStorage<TEntity>> _pumpScreenWithEnoughItems(WidgetTester tester, {
		TEntity Function(int) newEntityGetter, int searcherModeThreshold,
		Future<int> Function() itemsLengthGetter 
	}) => pumpScreen(tester, (st) async {
			int curLength;
			if (itemsLengthGetter == null)
				curLength = (await tester.runAsync(() => st.fetch())).length;
			else
				curLength = await itemsLengthGetter(); 
			
			final properLength = searcherModeThreshold + 5;
			while (curLength <= properLength) {
				await tester.runAsync(() => st.upsert([newEntityGetter(curLength)]));
				++curLength;
			}
		});

	Finder findSearcherEndButton({ bool shouldFind }) => 
        AssuredFinder.findOne(icon: Icons.search_off, shouldFind: shouldFind);
	
    Future<void> _activateSearchMode(WidgetAssistant assistant) =>
		assistant.tapWidget(_findSearcherButton(shouldFind: true));

    Finder _findSearcherButton({ bool shouldFind }) => 
        AssuredFinder.findOne(icon: Icons.search, shouldFind: shouldFind);

	void assureFilterIndexes(Iterable<String> indexes, { bool shouldFind }) =>
		indexes.forEach((i) => _findFilterIndex(i, shouldFind: shouldFind));

	Finder _findFilterIndex(String index, { bool shouldFind }) {
		final finder = find.widgetWithText(TextButton, index, skipOffstage: false);
		expect(finder, (shouldFind ?? false) ? findsOneWidget: findsNothing);

		return finder;
	}

    Future<void> deactivateSearcherMode(WidgetAssistant assistant) =>
        assistant.tapWidget(findSearcherEndButton(shouldFind: true));

	void assureFilterIndexActiveness(WidgetTester tester, String index, { bool isActive }) {
		final activeIndexBoxFinder = find.ancestor(of: _findFilterIndex(index, shouldFind: true), 
			matching: find.byType(Container));
		expect(tester.widgetList<Container>(activeIndexBoxFinder)
			.singleWhere((w) => (w?.decoration as BoxDecoration)?.border != null, 
			orElse: () => null) != null, isActive ?? false);
	}

	Future<void> chooseFilterIndex(WidgetAssistant assistant, String index) async {
		final activeIndexFinder = _findFilterIndex(index, shouldFind: true);
		await assistant.tapWidget(activeIndexFinder);
	}
	
	Future<void> _deleteAllItemsInEditor(WidgetAssistant assistant) async {
		await _selectAll(assistant);

		await deleteSelectedItems(assistant);
	}

	Future<void> _selectAll(WidgetAssistant assistant) =>
		assistant.tapWidget(_tryFindingEditorSelectButton(shouldFind: true));

	Future<void> deleteSelectedItems(WidgetAssistant assistant, {
		bool shouldCancel = false, bool shouldAccept = false, bool shouldNotWarn = false
	}) async {
		final removeBtnFinder = _tryFindingEditorRemoveButton(shouldFind: true);
		await assistant.tapWidget(removeBtnFinder);
		
		await _confirmRemovalIfNecessary(assistant, shouldCancel: shouldCancel, 
			shouldAccept: shouldAccept, shouldNotWarn: shouldNotWarn);
		await assistant.pumpAndAnimate(3000);

		await assistant.pumpAndAnimate(100);
	}

	Future<void> selectItemsInEditor(WidgetAssistant assistant, List<String> itemTitles) async {

		for (final title in itemTitles..sort((a, b) => a.compareTo(b))) {
			final tileFinder = await assistant.scrollUntilVisible(
				find.widgetWithText(CheckboxListTile, title), CheckboxListTile);

			await assistant.tapWidget(tileFinder);
		}
	}

	Future<void> _deleteItemsUntilSearchIsUnavailable(
		WidgetAssistant assistant, BaseStorage<TEntity> storage
	) async {
		final tester = assistant.tester;
		final indexGroups = await _getIndexGroups(tester, storage);
		final filterIndexesToDelete = <String>[];
		
		int overallLength = indexGroups.fold<int>(0, (res, e) => res + e.value);
		for (final gr in indexGroups) {
			filterIndexesToDelete.add(gr.key);

			overallLength -= gr.value;
			if (overallLength < _searcherModeThreshold)
				break;
		}

		final entities = <TEntity>[];
		for (final indexToDelete in filterIndexesToDelete)
			entities.addAll(await tester.runAsync(() => storage.fetch(textFilter: indexToDelete)));

		await activateEditorMode(assistant);
		await selectItemsInEditor(assistant, entities.map((i) => i.textData).toList());
		await deleteSelectedItems(assistant);
	}
}
