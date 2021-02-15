import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../data/base_storage.dart';
import '../consts.dart';
import '../models/stored_entity.dart';
import '../widgets/bar_scaffold.dart';
import '../utilities/styler.dart';

class _CachedItem<TItem> {
    final TItem item;

    final int index;

    _CachedItem(this.item, this.index);
}

abstract class ListScreenState<TItem extends StoredEntity, TWidget extends StatefulWidget> 
    extends State<TWidget> {
    static const int _removalTimeoutMs = 2000;

    static const int _itemsPerPage = 30;

    static const int _navBarRemovalOptionIndex = 0;
    static const int _navBarSelectAllOptionIndex = 1;

    bool _isEndOfData = false;
    bool _canFetch = false;
    
    bool _isEditorMode;
    bool _isSearchMode;

    int _pageIndex = 0;

    BuildContext _scaffoldContext;

	Map<String, int> _filterIndexes;
	String _curFilterIndex;
	String _filterIndexToDelete;

    final Map<int, _CachedItem<TItem>> _itemsMarkedForRemoval = {};
    final Map<int, _CachedItem<TItem>> _itemsMarkedInEditor = {};

    final List<TItem> _items = [];
    final ScrollController _scrollController = new ScrollController();
    
    @override
    initState() {
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

        if (nextItems.length == 0)
            _isEndOfData = true;
        else
			setState(() => _items.addAll(nextItems));
    }

    _expandListOnScroll() {
        if (_scrollController.position.extentAfter < 500 && !_isEndOfData && _canFetch)
            _fetchItems();
    }

    Future<List<TItem>> _fetchNextItems([String text]) => 
        fetchNextItems(_pageIndex++ * _itemsPerPage, _itemsPerPage, text);

    @protected
    Future<List<TItem>> fetchNextItems(int skipCount, int takeCount, String text);

    @override
    dispose() {
        _scrollController.removeListener(_expandListOnScroll);

        super.dispose();
    }

    @override
    Widget build(BuildContext buildContext) {
		final locale = AppLocalizations.of(buildContext);
        return new BarScaffold(title,
            barActions: <Widget>[
				_isEditorMode ? _buildEditorDoneButton(locale): _buildEditorButton(locale),
				
				if (_isSearchMode || _isSearchModeAvailable)
					(_isSearchMode ? _buildSearchDoneButton(): _buildSearchButton())
			],
            onNavGoingBack: canGoBack ? 
                () {
                    _deleteAllMarkedForRemoval();
                    onGoingBack(buildContext);
                }: null,
            bottomNavigationBar: _isEditorMode ? _buildBottomBar(locale): null,
            body: _buildListView(buildContext, locale),
            floatingActionButton: _buildNewItemButton(buildContext, locale)
        );
    }

	bool get _isSearchModeAvailable => 
		_curFilterIndex != null ||  _items.length > _itemsPerPage / 3;

    @protected
    String get title;

    Widget _buildEditorButton(AppLocalizations locale) => 
		new FlatButton(
			onPressed: () {
				setState(() => _isEditorMode = true);
			}, 
			child: new Text(locale.listScreenEditorEditingButtonLabel)
		);

    Widget _buildEditorDoneButton(AppLocalizations locale) => 
		new FlatButton(
			onPressed: () {
				setState(() { 
					_itemsMarkedInEditor.clear();
					_isEditorMode = false;
				});
			},
			child: new Text(locale.listScreenEditorDoneButtonLabel)
		);

	Widget _buildSearchButton() => new IconButton(
			onPressed: _filterIndexes == null ? null: () {
				setState(() => _isSearchMode = true);
			},
			icon: new Icon(Icons.search)
		);

	Widget _buildSearchDoneButton() => new IconButton(
        onPressed: () {
			_refetchItems();

            setState(() => _isSearchMode = false);
        },
		icon: new Icon(Icons.search_off)
    );

    @protected
    bool get canGoBack;

    @protected
    void onGoingBack(BuildContext context);

    Widget _buildBottomBar(AppLocalizations locale) {
        bool allSelected = _itemsMarkedInEditor.length == _removableItems.length;
        final options = getNavBarOptions(allSelected, locale);
        
        return new BottomNavigationBar(
            items: options,
            onTap: (tappedIndex) async {
                if (tappedIndex == _navBarRemovalOptionIndex) {
                    if (
						_itemsMarkedInEditor.length == 0 || 
						!(await shouldContinueRemoval(_itemsMarkedInEditor.values.map((v) => v.item).toList()))
					) return;

                    _itemsMarkedForRemoval.addAll(_itemsMarkedInEditor);

                    setState(() {
                        final idsMarkedForRemoval = _itemsMarkedInEditor.keys;
                        _items.removeWhere((w) => idsMarkedForRemoval.contains(w.id));

                        _showItemRemovalInfoSnackBar(
							scaffoldContext: _scaffoldContext,
							message: locale.listScreenBottomSnackBarRemovedItemsInfo(
								_itemsMarkedInEditor.length),
                            itemIdsToRemove: _itemsMarkedInEditor.keys.toList(), 
							locale: locale);

                        _itemsMarkedInEditor.clear();
                    });
                }
                else if (tappedIndex == _navBarSelectAllOptionIndex) {
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
                else if (await handleNavBarOption(tappedIndex, 
                    _itemsMarkedInEditor.values.map((e) => e.item), _scaffoldContext)) {
                    _itemsMarkedInEditor.clear();
                }
            }
        );
    }

	Iterable<TItem> get _removableItems => _items.where((w) => isRemovableItem(w));

    @protected
    List<BottomNavigationBarItem> getNavBarOptions(bool allSelected, AppLocalizations locale) {
        final options = new List<BottomNavigationBarItem>();
        options.insert(_navBarRemovalOptionIndex, new BottomNavigationBarItem(
            icon: new Icon(Icons.delete),
            label: locale.constsRemovingItemButtonLabel
        ));
        options.insert(_navBarSelectAllOptionIndex, new BottomNavigationBarItem(
            icon: new Icon(Icons.select_all),
            label: Consts.getSelectorLabel(allSelected, locale)
        ));

        return options;
    } 
        
    @protected
    Future<bool> handleNavBarOption(int tappedIndex, Iterable<TItem> markedItems,
        BuildContext scaffoldContext) async => Future.value(true);

    void _showItemRemovalInfoSnackBar({ 
		@required BuildContext scaffoldContext, @required String message, 
		@required List<int> itemIdsToRemove, @required AppLocalizations locale 
	}) {
        final snackBar = Scaffold.of(scaffoldContext ?? context).showSnackBar(new SnackBar(
			duration: new Duration(milliseconds: _removalTimeoutMs),
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
			onPressed: () => _refetchItems(index), 
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

	void _refetchItems([String text]) {
		if (_curFilterIndex == text)
			return;

		_deleteEmptyFilterIndex();

		_curFilterIndex = text;

		_pageIndex = 0;
		_items.clear();

		_fetchItems(text);
	}

	void _deleteEmptyFilterIndex() {
		if (_filterIndexToDelete == null)
			return;
		
		_filterIndexes.remove(_filterIndexToDelete);
		_filterIndexToDelete = null;
	}

    Widget _buildList(AppLocalizations locale) => 
		new Scrollbar(
			child: new ListView.builder(
				itemCount: _items.length,
				itemBuilder: _isEditorMode ? _buildCheckListItem: 
					(context, index) => _buildDismissibleListItem(context, index, locale),
				controller: _scrollController
			)
		);

    Widget _buildCheckListItem(BuildContext buildContext, int itemIndex) {
        _scaffoldContext = buildContext;
        final item = _items[itemIndex];
        
        return isRemovableItem(item) ? new CheckboxListTile(
            value: _itemsMarkedInEditor.containsKey(item.id),
            onChanged: (isChecked) {
                setState(() {
                    if (isChecked)
                        _itemsMarkedInEditor[item.id] = new _CachedItem(item, itemIndex);
                    else
                        _itemsMarkedInEditor.remove(item.id);
                });
            },
            secondary: getItemLeading(item),
            title: getItemTitle(item),
            subtitle: getItemSubtitle(item)
        ) : _buildListTile(buildContext, item, isReadonly: true);
    }

    @protected
    bool isRemovableItem(TItem item) => true;

    @protected
    Widget getItemLeading(TItem item) => null;

    @protected
    Widget getItemTitle(TItem item);

    @protected
    Widget getItemSubtitle(TItem item);

    Widget _buildListTile(BuildContext buildContext, TItem item, 
        { bool isReadonly = false }) => new ListTile(
            leading: getItemLeading(item),
            title: getItemTitle(item),
            trailing: getItemTrailing(item),
            subtitle: getItemSubtitle(item),
            onTap: () => isReadonly ? null: onGoingToItem(buildContext, item)
        );

    Widget _buildDismissibleListItem(
		BuildContext buildContext, int itemIndex, AppLocalizations locale
	) {
        final item = _items[itemIndex];

        bool shouldRemove = false;
        return isRemovableItem(item) ? new Dismissible(
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) => Future.delayed(
				new Duration(milliseconds: _removalTimeoutMs), () => shouldRemove),
            background: new Container(
                color: Colors.deepOrange[300], 
                child: new FlatButton.icon(
                    label: new Text(locale.constsRemovingItemButtonLabel),
                    icon: new Icon(Icons.delete), 
                    onPressed: () => shouldRemove = true
                )
            ),
            key: new Key(item.id.toString()),
            onDismissed: (direction) async {
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
            child: _buildListTile(buildContext, item)
        ): _buildListTile(buildContext, item);
    }

    @protected
    Widget getItemTrailing(TItem item) => null;

    _recoverMarkedForRemoval(List<int> ids) {
        final entries = _getEntriesMarkedForRemoval(ids).toList();
        if (entries.isEmpty)
            return;

        setState(() {
            entries.sort((a, b) => a.value.index.compareTo(b.value.index));
            entries.forEach((entry) => _items.insert(entry.value.index, entry.value.item));
            _deleteFromMarkedForRemoval(ids);
        });
    }

    List<MapEntry<int, _CachedItem<TItem>>> _getEntriesMarkedForRemoval(List<int> ids) =>
        _itemsMarkedForRemoval.entries.where((entry) => ids.contains(entry.key)).toList();

    _deleteFromMarkedForRemoval(List<int> ids) => 
        _itemsMarkedForRemoval.removeWhere((id, _) => ids.contains(id));

    _deleteMarkedForRemoval(List<int> ids) {
        if (_itemsMarkedForRemoval.isEmpty)
            return;

		final entriesForRemoval = new Map.fromEntries(_getEntriesMarkedForRemoval(ids));
        deleteItems(_extractItemsForDeletion(entriesForRemoval.values));
		_deleteFilterIndexes(entriesForRemoval.values.map(
			(v) => v.item.textData[0]).toList());

        _deleteFromMarkedForRemoval(ids);
    }
	
    @protected
    Future<bool> shouldContinueRemoval(List<TItem> itemsToRemove) async => 
		Future.value(true);

	List<TItem> _extractItemsForDeletion(Iterable<_CachedItem<TItem>> items) =>
		items.map((i) => i.item).toList();

    @protected
    void deleteItems(List<TItem> ids);

	void _deleteFilterIndexes(List<String> removedIndexes) {
		if (_curFilterIndex == null) {
			final grouppedIndexes = removedIndexes.fold<Map<String, int>>({}, (res, val) {
				final index = val[0].toUpperCase();
				res[index] = (res[index] ?? 0) + 1;
				return res;
			});

			final indexesToRemove = <String>[];
			grouppedIndexes.forEach((ind, length) {
				if (_filterIndexes[ind] == length)
					indexesToRemove.add(ind);
				else
					_filterIndexes[ind] -= length;
			});

			if (indexesToRemove.isNotEmpty)
				setState(() {
					indexesToRemove.forEach((ind) => _filterIndexes.remove(ind));

					if (_isSearchMode && !_isSearchModeAvailable)
						_isSearchMode = false;
				});

			return;	
		}

		if (_items.length == 0)
			_filterIndexToDelete = _curFilterIndex;
	}

    FloatingActionButton _buildNewItemButton(
		BuildContext buildContext, AppLocalizations locale
	) => new FloatingActionButton(
            onPressed: () => onGoingToItem(buildContext),
            child: new Icon(Icons.add_circle), 
            mini: true,
            tooltip: locale.listScreenAddingNewItemButtonTooltip,
            backgroundColor: new Styler(buildContext).floatingActionButtonColor
        );

    @mustCallSuper
    onGoingToItem(BuildContext buildContext, [TItem item]) {
        _deleteAllMarkedForRemoval();
    }
    
    _deleteAllMarkedForRemoval() {
        if (_itemsMarkedForRemoval.isEmpty)
            return;

        deleteItems(_extractItemsForDeletion(_itemsMarkedForRemoval.values));
        _itemsMarkedForRemoval.clear();
    }
}

abstract class ListScreen<T extends StoredEntity> extends StatefulWidget {
	BaseStorage<T> get storage;
}
