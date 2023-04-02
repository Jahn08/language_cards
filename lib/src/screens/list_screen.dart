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

abstract class ListScreenState<TItem extends StoredEntity, TWidget extends StatefulWidget> 
    extends State<TWidget> {
    static const int _removalTimeoutMs = 2000;

    bool _isEndOfData = false;
    bool _canFetch = false;
    
    bool _isEditorMode;
    bool _isSearchMode;

    int _pageIndex = 0;

	Map<String, int> _filterIndexes;
	String _curFilterIndex;

    final Map<int, _CachedItem<TItem>> _itemsMarkedForRemoval = {};
    final Map<int, _CachedItem<TItem>> _itemsMarkedInEditor = {};

    final List<TItem> _items = [];
    final ScrollController _scrollController = new ScrollController();
    
    @override
    void initState() {
        super.initState();
        
        _isEditorMode = false;
		_isSearchMode = false;

		_initFilterIndexes();

        _scrollController.addListener(_expandListOnScroll);

        _fetchItems();
    }

	Future<void> _initFilterIndexes() async {
		final filterIndexes = await getFilterIndexes();
		
		WidgetsBinding.instance.addPostFrameCallback((_) => 
			setState(() => _filterIndexes = filterIndexes));
	}

	@protected
	Future<Map<String, int>> getFilterIndexes();

    Future<void> _fetchItems([String text]) async {
        _canFetch = false;
        final nextItems = await _fetchNextItems(text);

        _canFetch = true;

        if (nextItems.isEmpty)
            _isEndOfData = true;
        else
			setState(() => _items.addAll(nextItems));
    }

    void _expandListOnScroll() {
        if (_scrollController.position.extentAfter < 500 && !_isEndOfData && _canFetch)
            _fetchItems(_curFilterIndex);
    }

    Future<List<TItem>> _fetchNextItems([String text]) => 
        fetchNextItems(_pageIndex++ * ListScreen.itemsPerPage, ListScreen.itemsPerPage, text);

    @protected
    Future<List<TItem>> fetchNextItems(int skipCount, int takeCount, String text);

    @override
    void dispose() {
        _scrollController.removeListener(_expandListOnScroll);

        super.dispose();
    }

    @override
    Widget build(BuildContext buildContext) {
		final locale = AppLocalizations.of(buildContext);
        return new BarScaffold(
			title: title,
            barActions: <Widget>[
				new IconButton(
					onPressed: () => setState(() {
						_isEditorMode = !_isEditorMode;
						if (!_isEditorMode)
							_itemsMarkedInEditor.clear();
					}),
					icon: new Icon(_isEditorMode ? Icons.edit_off: Icons.edit)
				),
				if (_isSearchMode || _getIsSearchModeAvailable(_items.length))
					_isSearchMode ? 
						new IconButton(
							onPressed: () {
								refetchItems();
								setState(() => _isSearchMode = false);
							},
							icon: const Icon(Icons.search_off)
						): 
						new IconButton(
							onPressed: _filterIndexes == null ? null: () {
								setState(() => _isSearchMode = true);
							},
							icon: const Icon(Icons.search)
						)
			],
            onNavGoingBack: canGoBack ? 
                () {
                    _deleteAllMarkedForRemoval();
                    onGoingBack(buildContext);
                }: null,
            bottomBar: _isEditorMode ? 
				new _BottomBar((scaffoldContext) => _buildBottomOptions(scaffoldContext)): null,
            body: _buildListView(buildContext, locale),
            floatingActionButton: _buildNewItemButton(buildContext, locale)
        );
    }

	bool _getIsSearchModeAvailable(int itemsLength) => 
		_curFilterIndex != null ||  itemsLength > ListScreen.searcherModeItemsThreshold;

    @protected
    String get title;

    @protected
    bool get canGoBack;

    @protected
	String get curFilterIndex => _curFilterIndex;
	
    @protected
	int get filterIndexLength => 
		curFilterIndex == null ? _itemsLengthFromIndexes : _filterIndexes[curFilterIndex];

	int get _itemsLengthFromIndexes => 
		_filterIndexes.values.fold<int>(0, (prevLength, curLength) => prevLength + curLength);

    @protected
    void onGoingBack(BuildContext context);
	
	Iterable<TItem> get _removableItems => _items.where((w) => isRemovableItem(w));

	List<Widget> _buildBottomOptions(BuildContext scaffoldContext) {
		final locale = AppLocalizations.of(scaffoldContext);

		final allSelected = _itemsMarkedInEditor.length == _removableItems.length;
		final options = getBottomBarOptions(_itemsMarkedInEditor.values.map((e) => e.item).toList(), 
			locale, scaffoldContext) ?? <Widget>[];
		options.addAll(_buildBottomBarOptions(allSelected, locale, scaffoldContext));
	
		return options;
	}

    @protected
	List<Widget> getBottomBarOptions(
		List<TItem> markedItems, AppLocalizations locale, BuildContext scaffoldContext
	) => <Widget>[];

    List<Widget> _buildBottomBarOptions(
		bool allSelected, AppLocalizations locale, BuildContext scaffoldContext
	) {
        return [ 
			new IconedButton(
				icon: const _DeleteIcon(),
				label: locale.constsRemovingItemButtonLabel,
				onPressed: () async {
					if (_itemsMarkedInEditor.isEmpty || 
						!(await shouldContinueRemoval(
							_itemsMarkedInEditor.values.map((v) => v.item).toList()
						)))
						return;

                    _itemsMarkedForRemoval.addAll(_itemsMarkedInEditor);

                    setState(() {
                        _items.removeWhere((w) => _itemsMarkedInEditor.containsKey(w.id));

                        _showItemRemovalInfoSnackBar(
							scaffoldContext: scaffoldContext,
							message: locale.listScreenBottomSnackBarRemovedItemsInfo(
								_itemsMarkedInEditor.length.toString()),
                            itemIdsToRemove: _itemsMarkedInEditor.keys.toList(), 
							locale: locale);

                        _itemsMarkedInEditor.clear();
                    });
				}
			),
			new IconedButton(
				icon: const Icon(Icons.select_all),
				label: getSelectorBtnLabel(allSelected: allSelected, locale: locale),
				onPressed: () {
					if (allSelected)
                        setState(() => _itemsMarkedInEditor.clear());
                    else {
                        setState(() {
							final itemsToMark = _removableItems.toList();
                            int index = _items.length - itemsToMark.length;

                            itemsToMark.forEach((w) =>
                                _itemsMarkedInEditor[w.id] = new _CachedItem(w, index++));
                        });
                    }
				}
			)
		];
    } 

	@protected
	String getSelectorBtnLabel({ bool allSelected, AppLocalizations locale }) {
		final itemsOverall = _removableItems.length.toString();
		return allSelected ? locale.constsUnselectAll(itemsOverall): 
			locale.constsSelectAll(itemsOverall);
	}

	@protected
	void clearItemsMarkedInEditor() => _itemsMarkedInEditor.clear();

    void _showItemRemovalInfoSnackBar({ 
		@required BuildContext scaffoldContext, @required String message, 
		@required List<int> itemIdsToRemove, @required AppLocalizations locale 
	}) {
        final snackBar = ScaffoldMessenger.of(scaffoldContext ?? context).showSnackBar(new SnackBar(
			duration: const Duration(milliseconds: _removalTimeoutMs),
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
				
				if (_isSearchMode)
					new Flexible(child: 
						new Scrollbar(
							child: new ListView(
								shrinkWrap: true,
								children: (_filterIndexes.keys.toList()..sort())
									.map((i) => _buildFilterIndex(context, i)).toList()
							)
						)
					)
			]
		);
    }

    Widget _buildFilterIndex(BuildContext context, String index) {
		final textBtn = new TextButton(
			onPressed: () => refetchItems(text: index), 
			child: new Text(index)
		);

		if (index == _curFilterIndex)
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

		if (!(isForceful ?? false) && _curFilterIndex == newFilterIndex) {
			if (_curFilterIndex == null)
				return;

			newFilterIndex = null;
		}

		_curFilterIndex = newFilterIndex;

		_pageIndex = 0;
		_items.clear();
		_itemsMarkedInEditor.clear();

		await _fetchItems(newFilterIndex);
	
		if (shouldInitIndices ?? false)
			_initFilterIndexes();
	}

    Widget _buildList(AppLocalizations locale) => 
		new Scrollbar(
			child: new ListView.builder(
				key: new ObjectKey(_curFilterIndex),
				itemCount: _items.length,
				itemBuilder: _isEditorMode ? _buildCheckListItem: 
					(context, index) => _buildDismissibleListItem(context, index, locale),
				controller: _scrollController
			)
		);

    Widget _buildCheckListItem(BuildContext buildContext, int itemIndex) {
        final item = _items[itemIndex];
        return new UnderlinedContainer(new CheckboxListTile(
            value: _itemsMarkedInEditor.containsKey(item.id),
            onChanged: isRemovableItem(item) ? (isChecked) {
                setState(() {
                    if (isChecked)
                        _itemsMarkedInEditor[item.id] = new _CachedItem(item, itemIndex);
                    else
                        _itemsMarkedInEditor.remove(item.id);
                });
            }: null,
			secondary: getItemLeading(item),
            title: getItemTitle(item),
            subtitle: getItemSubtitle(item, forCheckbox: true)
        ));
    }
	
    @protected
    bool isRemovableItem(TItem item) => true;

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
		BuildContext buildContext, int itemIndex, AppLocalizations locale
	) {
        final item = _items[itemIndex];

        return new UnderlinedContainer(isRemovableItem(item) ? new Dismissible(
			direction: DismissDirection.endToStart,
			key: new Key(item.id.toString()),
			background: new Container(
				color: Colors.deepOrange[300], 
				child: const _DeleteIcon()
			),
			onDismissed: (_) async {
				final itemToRemove = _items[itemIndex];
				_itemsMarkedForRemoval[itemToRemove.id] = 
					new _CachedItem(itemToRemove, itemIndex);

				setState(() => _items.remove(itemToRemove));

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
			child: _buildListTile(buildContext, item)): _buildListTile(buildContext, item)
		);
    }

    @protected
    Widget getItemTrailing(TItem item) => null;

    void _recoverMarkedForRemoval(List<int> ids) {
        final itemsToRecover = _getCachedItemsMarkedForRemoval(ids).toList();
        if (itemsToRecover.isEmpty)
            return;

        setState(() {
            itemsToRecover.forEach((i) => _items.insert(i.index, i.item));
            _deleteFromMarkedForRemoval(ids);
        });
    }

    List<_CachedItem<TItem>> _getCachedItemsMarkedForRemoval(List<int> ids) {
		return ids.map((id) => _itemsMarkedForRemoval[id]).toList();
	}

    void _deleteFromMarkedForRemoval(List<int> ids) => 
		ids.forEach((id) => _itemsMarkedForRemoval.remove(id));

    Future<void> _deleteMarkedForRemoval(List<int> ids) async {
        if (_itemsMarkedForRemoval.isEmpty)
            return;

		final itemsToDelete = _getCachedItemsMarkedForRemoval(ids);
		final removedIndexes = itemsToDelete.map((i) => i.item.textData[0]).toList();
		final indexesDeleted = _deleteFilterIndexes(removedIndexes);
		
        _deleteFromMarkedForRemoval(ids);
		deleteItems(_extractItemsForDeletion(itemsToDelete));

		final isSearchOff = _isSearchMode && !_getIsSearchModeAvailable(_itemsLengthFromIndexes);
		if (isSearchOff)
			_isSearchMode = false;

		if (_curFilterIndex != null && !_filterIndexes.containsKey(_curFilterIndex))
			await refetchItems();
		else
    		await updateStateAfterDeletion(shallUpdate: indexesDeleted || isSearchOff);		
    }
	
    @protected
    Future<bool> shouldContinueRemoval(List<TItem> itemsToRemove) async => 
		Future.value(true);

	List<TItem> _extractItemsForDeletion(Iterable<_CachedItem<TItem>> items) =>
		items.map((i) => i.item).toList();

    @protected
    void deleteItems(List<TItem> ids);
	
    @protected
    Future<void> updateStateAfterDeletion({ bool shallUpdate }) async {
		if (shallUpdate ?? false)
			setState(() {});
	}

	bool _deleteFilterIndexes(List<String> removedIndexes) {
		final grouppedIndexes = removedIndexes.fold<Map<String, int>>({}, (res, val) {
			final index = val[0].toUpperCase();
			res[index] = (res[index] ?? 0) + 1;
			return res;
		});

		final indexesToRemove = <String>[];
		grouppedIndexes.forEach((ind, length) {
			final indexLength = _filterIndexes[ind];
			if (indexLength == null)
				return;
			
			if (indexLength == length)
				indexesToRemove.add(ind);
			else
				_filterIndexes[ind] -= length;
		});

		if (indexesToRemove.isNotEmpty) {
			indexesToRemove.forEach((ind) => _filterIndexes.remove(ind));
			return true;
		}

		return false;
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
        if (_itemsMarkedForRemoval.isEmpty)
            return;

        deleteItems(_extractItemsForDeletion(_itemsMarkedForRemoval.values));
        _itemsMarkedForRemoval.clear();
    }
}

class _DeleteIcon extends Icon {

	const _DeleteIcon(): super(Icons.delete);
}

abstract class ListScreen<T extends StoredEntity> extends StatefulWidget {
	static const int itemsPerPage = 100;

    static const int searcherModeItemsThreshold = 10;

	const ListScreen();

	BaseStorage<T> get storage;
}
