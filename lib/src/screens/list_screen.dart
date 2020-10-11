import 'package:flutter/material.dart';
import '../blocs/settings_bloc.dart';
import '../models/stored_entity.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/settings_opener_button.dart';
import '../widgets/settings_panel.dart';

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

    int _pageIndex = 0;

    BuildContext _scaffoldContext;

    final Map<int, _CachedItem<TItem>> _itemsMarkedForRemoval = {};
    final Map<int, _CachedItem<TItem>> _itemsMarkedInEditor = {};

    final List<TItem> _items = [];
    final ScrollController _scrollController = new ScrollController();
    
    @override
    initState() {
        super.initState();
        
        _editorMode = false;

        _scrollController.addListener(_expandListOnScroll);

        _fetchItems();
    }

    _fetchItems() async {
        _canFetch = false;
        final nextItems = await _fetchNextItems();

        _canFetch = true;

        if (nextItems.length == 0)
            _endOfData = true;
        else
            setState(() { _items.addAll(nextItems); });
    }

    _expandListOnScroll() {
        if (_scrollController.position.extentAfter < 500 && !_endOfData && _canFetch)
            _fetchItems();
    }

    Future<List<TItem>> _fetchNextItems() => 
        fetchNextItems(_pageIndex++ * _itemsPerPage, _itemsPerPage);

    @protected
    Future<List<TItem>> fetchNextItems(int skipCount, int takeCount);

    @override
    dispose() {
        _scrollController.removeListener(_expandListOnScroll);

        super.dispose();
    }

    @override
    Widget build(BuildContext buildContext) {
        return new Scaffold(
            appBar: _buildAppBar(buildContext),
            bottomNavigationBar: _editorMode ? _buildBottomBar(): null,
            drawer: new SettingsBlocProvider(child: new SettingsPanel()),
            body: _buildList(),
            floatingActionButton: _buildNewCardButton(buildContext)
        );
    }

    Widget _buildAppBar(BuildContext buildContext) {
        final barTitle = new Text(title);
        final settingsOpenerBtn = new SettingsOpenerButton();
        final editorActions = <Widget>[_editorMode ? _buildEditorDoneButton(): 
            _buildEditorButton()];

        if (canGoBack)
            return new NavigationBar(barTitle, 
                leading: settingsOpenerBtn,
                actions: editorActions,
                onGoingBack: () {
                    _deleteAllMarkedForRemoval();
                    onGoingBack(buildContext);
                });
            
        return new AppBar(
            leading: settingsOpenerBtn,
            title: barTitle,
            actions: editorActions
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
            title: new Text('Remove')
        ));
        options.insert(_navBarSelectAllOptionIndex, new BottomNavigationBarItem(
            icon: new Icon(Icons.select_all),
            title: new Text('${allSelected ? 'Unselect': 'Select'} All')
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

    Widget _buildList() => new Scrollbar(
        child: new ListView.builder(
            itemCount: _items.length,
            itemBuilder: (listContext, index) => _editorMode ?
                _buildCheckListItem(listContext, index):
                _buildDismissibleListItem(listContext, index),
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
            title: getItemTitle(item),
            subtitle: getItemSubtitle(item)
        ) : _buildListTile(buildContext, item, isReadonly: true);
    }

    @protected
    bool isRemovableItem(TItem item) => true;

    @protected
    Widget getItemTitle(TItem item);

    @protected
    Widget getItemSubtitle(TItem item);

    Widget _buildListTile(BuildContext buildContext, TItem item, 
        { bool isReadonly = false }) => new ListTile(
            title: getItemTitle(item),
            trailing: getItemTrailing(item),
            subtitle: getItemSubtitle(item),
            onTap: () => isReadonly ? null: onGoingToItem(buildContext, item)
        );

    @protected
    Widget buildOneLineText(String data) => 
        new Text(data, maxLines: 1, overflow: TextOverflow.ellipsis);

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
    Widget getItemTrailing(TItem item);

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

    Widget _buildNewCardButton(BuildContext buildContext) {
        final theme = Theme.of(buildContext);
        return new FloatingActionButton(
            onPressed: () => onGoingToItem(buildContext),
            child: new Icon(Icons.add_circle), 
            mini: true,
            tooltip: 'New Card',
            backgroundColor: (theme.floatingActionButtonTheme.backgroundColor ?? 
                theme.colorScheme.secondary).withOpacity(0.3)
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
