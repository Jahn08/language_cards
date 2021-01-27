import 'package:flutter/material.dart';
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
    static const int _itemsPerPage = 30;

    static const int _navBarRemovalOptionIndex = 0;
    static const int _navBarSelectAllOptionIndex = 1;

    bool _endOfData = false;
    bool _canFetch = false;
    
    bool _editorMode;
    bool _searchMode;

    int _pageIndex = 0;

    BuildContext _scaffoldContext;

	List<String> _filterIndexes;
	String _curFilterIndex;

    final Map<int, _CachedItem<TItem>> _itemsMarkedForRemoval = {};
    final Map<int, _CachedItem<TItem>> _itemsMarkedInEditor = {};

    final List<TItem> _items = [];
    final ScrollController _scrollController = new ScrollController();
    
    @override
    initState() {
        super.initState();
        
        _editorMode = false;
		_searchMode = false;

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
	Future<List<String>> getFilterIndexes();

    Future<void> _fetchItems([String text]) async {
        _canFetch = false;
        final nextItems = await _fetchNextItems(text);

        _canFetch = true;

        if (nextItems.length == 0)
            _endOfData = true;
        else
			setState(() => _items.addAll(nextItems));
    }

    _expandListOnScroll() {
        if (_scrollController.position.extentAfter < 500 && !_endOfData && _canFetch)
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
		final isSearchModeAvailable = _curFilterIndex != null || 
			_items.length > _itemsPerPage / 3;
        return new BarScaffold(title,
            barActions: <Widget>[
				_editorMode ? _buildEditorDoneButton(): _buildEditorButton(),
				
				if (isSearchModeAvailable)
					(_searchMode ? _buildSearchDoneButton(): _buildSearchButton())
			],
            onNavGoingBack: canGoBack ? 
                () {
                    _deleteAllMarkedForRemoval();
                    onGoingBack(buildContext);
                }: null,
            bottomNavigationBar: _editorMode ? _buildBottomBar(): null,
            body: _buildListView(buildContext),
            floatingActionButton: _buildNewCardButton(buildContext)
        );
    }

    @protected
    String get title;

    Widget _buildEditorButton() => new FlatButton(
        onPressed: () {
            setState(() => _editorMode = true);
        }, 
        child: new Text('Edit')
    );

    Widget _buildEditorDoneButton() => new FlatButton(
        onPressed: () {
            setState(() { 
                _itemsMarkedInEditor.clear();
                _editorMode = false;
            });
        },
        child: new Text('Done')
    );

	Widget _buildSearchButton() => new IconButton(
			onPressed: _filterIndexes == null ? null: () {
				setState(() => _searchMode = true);
			},
			icon: new Icon(Icons.search)
		);

	Widget _buildSearchDoneButton() => new IconButton(
        onPressed: () {
			_refetchItems();

            setState(() => _searchMode = false);
        },
		icon: new Icon(Icons.search_off)
    );

    @protected
    bool get canGoBack;

    @protected
    void onGoingBack(BuildContext context);

    Widget _buildBottomBar() {
        bool allSelected = _itemsMarkedInEditor.length == _items.length;
        final options = getNavBarOptions(allSelected);
        
        return new BottomNavigationBar(
            items: options,
            onTap: (tappedIndex) async {
                if (tappedIndex == _navBarRemovalOptionIndex) {
                    if (_itemsMarkedInEditor.length == 0)
                        return;

                    _itemsMarkedForRemoval.addAll(_itemsMarkedInEditor);

                    setState(() {
                        final idsMarkedForRemoval = _itemsMarkedInEditor.keys;
                        _items.removeWhere((w) => idsMarkedForRemoval.contains(w.id));

                        _showItemRemovalInfoSnackBar(_scaffoldContext,
                            '${_itemsMarkedInEditor.length} items have been removed',
                            _itemsMarkedInEditor.keys.toList());

                        _itemsMarkedInEditor.clear();
                    });
                }
                else if (tappedIndex == _navBarSelectAllOptionIndex) {
                    if (allSelected)
                        setState(() => _itemsMarkedInEditor.clear());
                    else {
                        setState(() {
                            int index = 0;
                            _items.forEach((w) =>
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

    @protected
    List<BottomNavigationBarItem> getNavBarOptions(bool allSelected) {
        final options = new List<BottomNavigationBarItem>();
        options.insert(_navBarRemovalOptionIndex, new BottomNavigationBarItem(
            icon: new Icon(Icons.delete),
            label: 'Remove'
        ));
        options.insert(_navBarSelectAllOptionIndex, new BottomNavigationBarItem(
            icon: new Icon(Icons.select_all),
            label: Consts.getSelectorLabel(allSelected)
        ));

        return options;
    } 
        
    @protected
    Future<bool> handleNavBarOption(int tappedIndex, Iterable<TItem> markedItems,
        BuildContext scaffoldContext) async => Future.value(true);

    void _showItemRemovalInfoSnackBar(BuildContext scaffoldContext, String message, 
        List<int> itemIdsToRemove) {
        final snackBar = Scaffold.of(scaffoldContext ?? context).showSnackBar(new SnackBar(
            content: new Text(message),
            action: SnackBarAction(
                label: 'Undo',
                onPressed: () => _recoverMarkedForRemoval(itemIdsToRemove)
            )
        ));

        snackBar.closed.then((value) {
            if (value == SnackBarClosedReason.timeout)
                _deleteMarkedForRemoval(itemIdsToRemove);
        });
    }

    Widget _buildListView(BuildContext context) {
        return new Flex(
			direction: Axis.horizontal,
			children: [
				new Flexible(child: _buildList(), flex: 8, fit: FlexFit.tight),
				
				if (_searchMode)
					new Flexible(child: 
						new Scrollbar(
							child: new ListView(
								shrinkWrap: true,
								children: _filterIndexes.map((i) => _buildFilterIndex(context, i))
									.toList()
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

		_curFilterIndex = text;

		_pageIndex = 0;
		_items.clear();

		_fetchItems(text);
	}

    Widget _buildList() => new Scrollbar(
        child: new ListView.builder(
            itemCount: _items.length,
            itemBuilder: _editorMode ? _buildCheckListItem: _buildDismissibleListItem,
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

    Widget _buildDismissibleListItem(BuildContext buildContext, int itemIndex) {
        final item = _items[itemIndex];

        bool shouldRemove = false;
        return isRemovableItem(item) ? new Dismissible(
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) => Future.delayed(new Duration(milliseconds: 2000), 
                () => shouldRemove),
            background: new Container(
                color: Colors.deepOrange[300], 
                child: new FlatButton.icon(
                    label: new Text('Remove'),
                    icon: new Icon(Icons.delete), 
                    onPressed: () => shouldRemove = true
                )
            ),
            key: new Key(item.id.toString()),
            onDismissed: (direction) {
                final itemToRemove = _items[itemIndex];
                _itemsMarkedForRemoval[itemToRemove.id] = 
                    new _CachedItem(itemToRemove, itemIndex);

                _showItemRemovalInfoSnackBar(buildContext, 
                    'The item ${getItemTitle(itemToRemove)} has been removed',
                    [itemToRemove.id]);

                setState(() => _items.remove(itemToRemove));
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

    List<MapEntry<int, _CachedItem>> _getEntriesMarkedForRemoval(List<int> ids) =>
        _itemsMarkedForRemoval.entries.where((entry) => ids.contains(entry.key)).toList();

    _deleteFromMarkedForRemoval(List<int> ids) => 
        _itemsMarkedForRemoval.removeWhere((id, _) => ids.contains(id));

    _deleteMarkedForRemoval(List<int> ids) {
        if (_itemsMarkedForRemoval.isEmpty)
            return;

        removeItems(_getEntriesMarkedForRemoval(ids).map((entry) => entry.key).toList());
        _deleteFromMarkedForRemoval(ids);
    }

    @protected
    void removeItems(List<int> ids);

    FloatingActionButton _buildNewCardButton(BuildContext buildContext) {
        return new FloatingActionButton(
            onPressed: () => onGoingToItem(buildContext),
            child: new Icon(Icons.add_circle), 
            mini: true,
            tooltip: 'New Card',
            backgroundColor: new Styler(buildContext).floatingActionButtonColor
        );
    }

    @mustCallSuper
    onGoingToItem(BuildContext buildContext, [TItem item]) {
        _deleteAllMarkedForRemoval();
    }
    
    _deleteAllMarkedForRemoval() {
        if (_itemsMarkedForRemoval.isEmpty)
            return;

        removeItems(_itemsMarkedForRemoval.keys.toList());
        _itemsMarkedForRemoval.clear();
    }
}
