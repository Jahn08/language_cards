import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../data/base_storage.dart';
import '../models/stored_entity.dart';
import '../widgets/bar_scaffold.dart';
import '../widgets/iconed_button.dart';
import '../widgets/underlined_container.dart';
import '../utilities/styler.dart';

class _CachedItem<TItem> {
    final TItem item;

    final int index;

    const _CachedItem(this.item, this.index);
}

class _BottomBar extends StatelessWidget {
	
	final List<Widget> Function(BuildContext) optionsBuilder;

	const _BottomBar(this.optionsBuilder);

	@override
	Widget build(BuildContext context) => 
		new BottomAppBar(
			child: new Row(children: optionsBuilder(context),
				mainAxisAlignment: MainAxisAlignment.spaceAround),
			shape: const CircularNotchedRectangle()
		);
}

class _ListNotifier<T> extends ValueNotifier<List<T>> {
	  
	_ListNotifier([List<T> value]) : super(value ?? <T>[]);

	void clear() {
		if (value == null || value.isEmpty)
			return;

		value.clear();
		notifyListeners();
	}

	@override
	set value(List<T> newValue) {
		final valueToSet = newValue ?? <T>[];
		if ((value.length + valueToSet.length) == 0)
			return;
			
		super.value = valueToSet;
	}

	void add(T item) {
		value.add(item);
		notifyListeners();
	}
	
	void addAll(Iterable<T> items) {
		value.addAll(items);
		notifyListeners();
	}

	void removeWhere(bool Function(T) test) {
		value.removeWhere(test);
		notifyListeners();
	}

	void remove(T item) {
		value.remove(item);
		notifyListeners();
	}
}

class _MapNotifier<TKey, TValue> extends ValueNotifier<Map<TKey, TValue>> {
	  
	_MapNotifier([Map<TKey, TValue> value]) : super(value ?? {});

	void clear() {
		if (value == null || value.isEmpty)
			return;

		value.clear();
		notifyListeners();	
	}

	@override
	set value(Map<TKey, TValue> newValue) {
		final valueToSet = newValue ?? {};
		if ((value.length + valueToSet.length) == 0)
			return;
			
		super.value = valueToSet;
	}

	void upsert(TKey key, TValue item) {
		value[key] = item;
		notifyListeners();
	}

	void upsertAll(Iterable<MapEntry<TKey, TValue>> entries) {
		final inEntries = entries ?? {};
		if (inEntries.isEmpty)
			return;

		value.addEntries(entries);
		notifyListeners();
	}

	void remove(TKey key) {
		if (value.remove(key) == null)
			return;

		notifyListeners();
	}

	void removeAll(Iterable<TKey> keys) {
		final inKeys = keys ?? <TKey>[];
		if (inKeys.isEmpty)
			return;

		value.removeWhere((k, v) => keys.contains(k));
		notifyListeners();
	}
}

abstract class ListScreenState<TItem extends StoredEntity, TWidget extends StatefulWidget> 
    extends State<TWidget> {

    bool _canFetch = false;
    
    final _isEditorModeNotifier = new ValueNotifier(false);
    final _isSearchModeNotifier = new ValueNotifier(false);

    int _pageIndex = 0;

	final _filterIndexesNotifier = new _MapNotifier<String, int>();
	final _curFilterIndexNotifier = new ValueNotifier<String>(null);

    final Map<int, _CachedItem<TItem>> _itemsToRemove = {};

    final _markedItemsNotifier = new _MapNotifier<int, _CachedItem<TItem>>();

	final _itemsNotifier = new _ListNotifier<TItem>();
    final ScrollController _scrollController = new ScrollController();
    
    @override
    void initState() {
        super.initState();

		_initFilterIndexes();

        _scrollController.addListener(_expandListOnScroll);

        _fetchItems();
    }

	Future<void> _initFilterIndexes() async {
		_filterIndexesNotifier.value = await getFilterIndexes();
	}

	@protected
	Future<Map<String, int>> getFilterIndexes();

    Future<void> _fetchItems([String text]) async {
        _canFetch = false;
        final nextItems = await _fetchNextItems(text);

        if (nextItems.isNotEmpty) {
        	_canFetch = true;
			_itemsNotifier.addAll(nextItems);
		}
    }

    void _expandListOnScroll() {
        if (_scrollController.position.extentAfter < 500 && _canFetch)
            _fetchItems(curFilterIndex);
    }

    Future<List<TItem>> _fetchNextItems([String text]) => 
        fetchNextItems(_pageIndex++ * ListScreen.itemsPerPage, ListScreen.itemsPerPage, text);

    @protected
    Future<List<TItem>> fetchNextItems(int skipCount, int takeCount, String text);

    @override
    void dispose() {
        _scrollController.removeListener(_expandListOnScroll);

		_isEditorModeNotifier.dispose();
		_isSearchModeNotifier.dispose();
		_filterIndexesNotifier.dispose();
		_markedItemsNotifier.dispose();
		_itemsNotifier.dispose();
        _curFilterIndexNotifier.dispose();

		super.dispose();
    }

    @override
    Widget build(BuildContext buildContext) {
		final locale = AppLocalizations.of(buildContext);
        return new BarScaffold(
			title: title,
            barActions: <Widget>[
				new IconButton(
					onPressed: () {
						_isEditorModeNotifier.value = !_isEditorModeNotifier.value;
						if (!_isEditorModeNotifier.value)
							_markedItemsNotifier.value.clear();
					},
					icon: new ValueListenableBuilder(
						valueListenable: _isEditorModeNotifier, 
						builder: (_, bool isEditorMode, __) => new Icon(isEditorMode ? Icons.edit_off: Icons.edit)
					)
				),
				new ValueListenableBuilder(
					valueListenable: _isSearchModeNotifier, 
					builder: (_, bool isSearchMode, __) {
						if (isSearchMode)
							return new IconButton(
								onPressed: () {
									refetchItems();
									_isSearchModeNotifier.value = false;
								},
								icon: const Icon(Icons.search_off)
							);
						
							return new ValueListenableBuilder(
								valueListenable: _filterIndexesNotifier, 
								builder: (_, Map<String, int> filterIndexes, __) {
									if (_getIsSearchModeAvailable(filterIndexLength))
										return new IconButton(
											onPressed: filterIndexes == null ? null: () {
												_isSearchModeNotifier.value = true;
											},
											icon: const Icon(Icons.search)
										);

									return const SizedBox.shrink();
								}
							);
					}
				)
			],
            onNavGoingBack: canGoBack ? 
                () {
                    _deleteAllMarkedForRemoval();
                    onGoingBack(buildContext);
                }: null,
            bottomBar: new ValueListenableBuilder(
				valueListenable: _isEditorModeNotifier, 
				builder: (_, bool isEditorMode, __) {
					if (isEditorMode)
						return new ValueListenableBuilder(
							valueListenable: _markedItemsNotifier, 
							builder: (_, Map<int, _CachedItem<TItem>> markedItems, __) {
								final items = markedItems.values.map((e) => e.item).toList();
								return new _BottomBar((scaffoldContext) => _buildBottomOptions(scaffoldContext, items));
							}
						);

					return const SizedBox.shrink();
				}
			),
            body: _buildListView(buildContext, locale),
            floatingActionButton: _buildNewItemButton(buildContext, locale)
        );
    }

	bool _getIsSearchModeAvailable(int itemsLength) => 
		curFilterIndex != null ||  itemsLength >= ListScreen.searcherModeItemsThreshold;

    @protected
    String get title;

    @protected
    bool get canGoBack;

    @protected
	String get curFilterIndex => _curFilterIndexNotifier.value;
	
    @protected
	int get filterIndexLength => 
		curFilterIndex == null ? _itemsLengthFromIndexes : _filterIndexesNotifier.value[curFilterIndex];

	int get _itemsLengthFromIndexes => 
		_filterIndexesNotifier.value.values.fold<int>(0, (prevLength, curLength) => prevLength + curLength);

    @protected
    void onGoingBack(BuildContext context);

	@protected
	int get removableItemsLength => _itemsNotifier.value.length;

    @protected
	Set<int> get nonRemovableItemIds => <int>{};

    bool _isRemovableItem(TItem item) => !nonRemovableItemIds.contains(item.id);

	List<Widget> _buildBottomOptions(BuildContext scaffoldContext, List<TItem> markedItems) {
		final locale = AppLocalizations.of(scaffoldContext);
		final options = getBottomBarOptions(markedItems, locale, scaffoldContext) ?? <Widget>[];
		options.addAll(_buildBottomBarOptions(locale, scaffoldContext));
	
		return options;
	}

    @protected
	List<Widget> getBottomBarOptions(
		List<TItem> markedItems, AppLocalizations locale, BuildContext scaffoldContext
	) => <Widget>[];

    List<Widget> _buildBottomBarOptions(AppLocalizations locale, BuildContext scaffoldContext) => [ 
		new IconedButton(
			icon: const _DeleteIcon(),
			label: locale.constsRemovingItemButtonLabel,
			onPressed: () async {
				final markedItems = _markedItemsNotifier.value;
				if (markedItems.isEmpty)
					return;

				final continueRemoval = await shouldContinueRemoval(markedItems.values.map((v) => v.item).toList());
				if (!continueRemoval)
					return;

				_itemsToRemove.addAll(markedItems);
				_itemsNotifier.removeWhere((w) => markedItems.containsKey(w.id));

				_showItemRemovalInfoSnackBar(
					scaffoldContext: scaffoldContext,
					message: locale.listScreenBottomSnackBarRemovedItemsInfo(markedItems.length.toString()),
					itemIdsToRemove: markedItems.keys.toList(), 
					locale: locale
				);

				_markedItemsNotifier.clear();
			}
		),
		new IconedButton.labelWidget(
			icon: const Icon(Icons.select_all),
			labelWidget: new ValueListenableBuilder(
				valueListenable: _itemsNotifier, 
				builder: (_, __, ___) => 
					new Text(getSelectorBtnLabel(
						allSelected: removableItemsLength == _markedItemsNotifier.value.length, 
						locale: locale
					))
			),
			onPressed: () {
				final allSelected = removableItemsLength == _markedItemsNotifier.value.length;
				if (allSelected) {
					clearItemsMarkedInEditor();
					return;
				}
				
				final items = _itemsNotifier.value;
				int index = items.length - removableItemsLength;
				
				final nonRemovableIds = nonRemovableItemIds.toSet();
				_markedItemsNotifier.upsertAll(
					items.where((i) => !nonRemovableIds.contains(i.id))
						.map((i) => new MapEntry(i.id, new _CachedItem(i, index++)))
				);
			}
		)
	];

	@protected
	String getSelectorBtnLabel({ bool allSelected, AppLocalizations locale }) {
		final itemsOverall = removableItemsLength.toString();
		return allSelected ? locale.constsUnselectAll(itemsOverall): 
			locale.constsSelectAll(itemsOverall);
	}

	@protected
	void clearItemsMarkedInEditor() => _markedItemsNotifier.clear();

    void _showItemRemovalInfoSnackBar({ 
		@required BuildContext scaffoldContext, @required String message, 
		@required List<int> itemIdsToRemove, @required AppLocalizations locale 
	}) {
        final snackBar = ScaffoldMessenger.of(scaffoldContext ?? context).showSnackBar(new SnackBar(
			duration: const Duration(milliseconds: ListScreen.removalTimeoutMs),
            content: new Text(message),
            action: SnackBarAction(
                label: locale.listScreenBottomSnackBarUndoingActionLabel,
                onPressed: () => _recoverMarkedForRemoval(itemIdsToRemove)
            )
        ));

        snackBar.closed.then((value) {
            if (value == SnackBarClosedReason.timeout)
                _deleteMarkedForRemoval(itemIdsToRemove);
        });
    }

    Widget _buildListView(BuildContext context, AppLocalizations locale) {
        return new Flex(
			direction: Axis.horizontal,
			children: [
				new Flexible(child: _buildList(locale), flex: 8, fit: FlexFit.tight),
				
				new ValueListenableBuilder(
					valueListenable: _isSearchModeNotifier, 
					builder: (_, bool isSearchMode, __) {
						if (isSearchMode)
							return new Flexible(child: 
								new Scrollbar(
									child: new ValueListenableBuilder(
										valueListenable: _filterIndexesNotifier, 
										builder: (_, Map<String, int> filterIndexes, __) =>

											new ValueListenableBuilder(
												valueListenable: _curFilterIndexNotifier, 
												builder: (_, String curIndex, __) => 
													new ListView(
														shrinkWrap: true,
														children: (filterIndexes.keys.toList()..sort())
															.map((i) => _buildFilterIndex(context, i, curIndex)).toList()
													)
											)
									)
								)
							);

						return const SizedBox.shrink();
					}
				)
			]
		);
    }

    Widget _buildFilterIndex(BuildContext context, String index, String curIndex) {
		final textBtn = new TextButton(
			onPressed: () => refetchItems(text: index), 
			child: new Text(index)
		);

		if (index == curIndex)
			return new Container(
				child: textBtn, 
				decoration: new BoxDecoration(
					border: new Border.all(color: new Styler(context).primaryColor)
				)
			);
				
		return textBtn;
    }

	@protected
	Future<void> refetchItems({ String text, bool isForceful, bool shouldInitIndices }) async {
		String newFilterIndex = text;

		if (!(isForceful ?? false) && curFilterIndex == newFilterIndex) {
			if (curFilterIndex == null)
				return;

			newFilterIndex = null;
		}

		if (curFilterIndex != newFilterIndex) {
			_curFilterIndexNotifier.value = newFilterIndex;
			_markedItemsNotifier.value.clear();
		}

		_pageIndex = 0;
		_itemsNotifier.value.clear();

		await _fetchItems(newFilterIndex);
	
		if (shouldInitIndices ?? false)
			await _initFilterIndexes();
	}

    Widget _buildList(AppLocalizations locale) => 
		new Scrollbar(
			child: new ValueListenableBuilder(
				valueListenable: _isEditorModeNotifier, 
				builder: (_, bool isEditorMode, __) {

					return new ValueListenableBuilder(
						valueListenable: _itemsNotifier, 
						builder: (_, List<TItem> items, __) {
							if (isEditorMode)
								return new ListView.builder(
									key: new ObjectKey(curFilterIndex),
									itemCount: items.length,
									itemBuilder: (BuildContext context, int index) {
										
										return new ValueListenableBuilder(
											valueListenable: _markedItemsNotifier, 
											builder: (_, Map<int, _CachedItem<TItem>> markedItems, __) => 
												_buildCheckListItem(context, index, items[index], markedItems.keys.toSet())
										);
									},
									controller: _scrollController
								);
					
							return new ListView.builder(
								key: new ObjectKey(curFilterIndex),
								itemCount: items.length,
								itemBuilder: (context, index) => _buildDismissibleListItem(context, index, locale, items[index]),
								controller: _scrollController
							);
						}
					);
				}
			)
		);

    Widget _buildCheckListItem(BuildContext buildContext, int itemIndex, TItem item, Set<int> markedIds) {
        return new UnderlinedContainer(
			new CheckboxListTile(
				value: markedIds.contains(item.id),
				onChanged: _isRemovableItem(item) ? 
					(isChecked) {
						if (isChecked)
							_markedItemsNotifier.upsert(item.id, new _CachedItem(item, itemIndex));
						else
							_markedItemsNotifier.remove(item.id);
					}: null,
				secondary: getItemLeading(item),
				title: getItemTitle(item),
				subtitle: getItemSubtitle(item, forCheckbox: true)
			)
		);
    }

    @protected
    Widget getItemLeading(TItem item) => null;

    @protected
    Widget getItemTitle(TItem item);

    @protected
    Widget getItemSubtitle(TItem item, { bool forCheckbox });

    Widget _buildListTile(BuildContext buildContext, TItem item) => 
		new ListTile(
            leading: getItemLeading(item),
            title: getItemTitle(item),
            trailing: getItemTrailing(item),
            subtitle: getItemSubtitle(item),
            onTap: () => onGoingToItem(buildContext, item)
        );

    Widget _buildDismissibleListItem(
		BuildContext buildContext, int itemIndex, AppLocalizations locale, TItem item
	) {
        return new UnderlinedContainer(_isRemovableItem(item) ? 
			new Dismissible(
				direction: DismissDirection.endToStart,
				key: new Key(item.id.toString()),
				background: new Container(
					color: Colors.deepOrange[300], 
					child: const _DeleteIcon()
				),
				onDismissed: (_) async {
					final itemToRemove = item;
					_itemsToRemove[itemToRemove.id] = 
						new _CachedItem(itemToRemove, itemIndex);

					_itemsNotifier.remove(itemToRemove);

					if (await shouldContinueRemoval([itemToRemove]))
						_showItemRemovalInfoSnackBar(
							scaffoldContext: buildContext,
							message: locale.listScreenBottomSnackBarDismissedItemInfo(
								itemToRemove.textData),
							itemIdsToRemove: [itemToRemove.id],
							locale: locale
						);
					else
						_recoverMarkedForRemoval([itemToRemove.id]);
				},
				child: _buildListTile(buildContext, item)
			): _buildListTile(buildContext, item)
		);
    }

    @protected
    Widget getItemTrailing(TItem item) => null;

    void _recoverMarkedForRemoval(List<int> ids) {
        final itemsToRecover = _getCachedItemsMarkedForRemoval(ids).toList();
        if (itemsToRecover.isEmpty)
            return;

		final items = new List<TItem>.from(_itemsNotifier.value);
		itemsToRecover.forEach((i) => items.insert(i.index, i.item));
		_itemsNotifier.value = items;

		_deleteFromMarkedForRemoval(ids);
    }

    List<_CachedItem<TItem>> _getCachedItemsMarkedForRemoval(List<int> ids) {
		return ids.map((id) => _itemsToRemove[id]).toList();
	}

    void _deleteFromMarkedForRemoval(List<int> ids) => 
		ids.forEach((id) => _itemsToRemove.remove(id));

    Future<void> _deleteMarkedForRemoval(List<int> ids) async {
        if (_itemsToRemove.isEmpty)
            return;

		final itemsToDelete = _getCachedItemsMarkedForRemoval(ids);
		final removedIndexes = itemsToDelete.map((i) => i.item.textData[0]).toList();
		_deleteFilterIndexes(removedIndexes);
		
        _deleteFromMarkedForRemoval(ids);
		deleteItems(_extractItemsForDeletion(itemsToDelete));

		final isSearchOff = _isSearchModeNotifier.value && !_getIsSearchModeAvailable(_itemsLengthFromIndexes);
		if (isSearchOff)
			_isSearchModeNotifier.value = false;

		if (curFilterIndex != null && !_filterIndexesNotifier.value.containsKey(curFilterIndex))
			await refetchItems();
		else
    		await updateStateAfterDeletion();
    }
	
    @protected
    Future<bool> shouldContinueRemoval(List<TItem> itemsToRemove) async => 
		Future.value(true);

	List<TItem> _extractItemsForDeletion(Iterable<_CachedItem<TItem>> items) =>
		items.map((i) => i.item).toList();

    @protected
    void deleteItems(List<TItem> ids);
	
    @protected
    Future<void> updateStateAfterDeletion() async { }

	void _deleteFilterIndexes(List<String> removedIndexes) {
		final grouppedIndexes = removedIndexes.fold<Map<String, int>>({}, (res, val) {
			final index = val[0].toUpperCase();
			res[index] = (res[index] ?? 0) + 1;
			return res;
		});

		final indexesToRemove = <String>[];
		final filterIndexes = _filterIndexesNotifier.value;
		grouppedIndexes.forEach((ind, length) {
			final indexLength = filterIndexes[ind];
			if (indexLength == null)
				return;
			
			if (indexLength == length)
				indexesToRemove.add(ind);
			else
				filterIndexes[ind] -= length;
		});

		if (indexesToRemove.isNotEmpty)
			_filterIndexesNotifier.removeAll(indexesToRemove);
	}

    FloatingActionButton _buildNewItemButton(
		BuildContext buildContext, AppLocalizations locale
	) => new FloatingActionButton(
            onPressed: () => onGoingToItem(buildContext),
            child: const Icon(Icons.add_circle), 
            mini: new Styler(buildContext).isDense,
            tooltip: locale.listScreenAddingNewItemButtonTooltip,
            backgroundColor: new Styler(buildContext).floatingActionButtonColor
        );

    @mustCallSuper
    void onGoingToItem(BuildContext buildContext, [TItem item]) => _deleteAllMarkedForRemoval();
    
    void _deleteAllMarkedForRemoval() {
        if (_itemsToRemove.isEmpty)
            return;

        deleteItems(_extractItemsForDeletion(_itemsToRemove.values));
        _itemsToRemove.clear();
    }
}

class _DeleteIcon extends Icon {

	const _DeleteIcon(): super(Icons.delete);
}

abstract class ListScreen<T extends StoredEntity> extends StatefulWidget {
	static const int itemsPerPage = 100;

    static const int searcherModeItemsThreshold = 10;

    static const int removalTimeoutMs = 2000;

	const ListScreen();

	BaseStorage<T> get storage;
}
