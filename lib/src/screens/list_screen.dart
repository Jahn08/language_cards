import 'package:flutter/material.dart';
import '../blocs/settings_bloc.dart';
import '../data/base_storage.dart';
import '../models/stored_entity.dart';
import '../widgets/settings_opener_button.dart';
import '../widgets/settings_panel.dart';

class _CachedItem<TItem> {
    final TItem item;

    final int index;

    _CachedItem(this.item, this.index);
}

abstract class ListScreenState<TItem extends StoredEntity> extends State<ListScreen> {
    static const int _itemsPerPage = 30;

    bool _endOfData = false;
    bool _canFetch = false;
    
    bool _editorMode;

    int _pageIndex = 0;

    BuildContext _scaffoldContext;

    final Map<int, _CachedItem<TItem>> _itemsMarkedForRemoval = {};
    final Map<int, _CachedItem<TItem>> _itemsMarkedForRemovalInEditor = {};

    final List<TItem> _items = [];
    final ScrollController _scrollController = new ScrollController();

    BaseStorage get _storage => widget.storage;
    
    @override
    initState() {
        super.initState();
        
        _editorMode = false;

        _scrollController.addListener(_expandListOnScroll);

        _fetchItems();
    }

    _fetchItems() async {
        _canFetch = false;
        final nextIems = await _fetchNextItems();

        _canFetch = true;

        if (nextIems.length == 0)
            _endOfData = true;
        else
            setState(() { _items.addAll(nextIems); });
    }

    _expandListOnScroll() {
        if (_scrollController.position.extentAfter < 500 && !_endOfData && _canFetch)
            _fetchItems();
    }

    Future<List<TItem>> _fetchNextItems() => 
        _storage.fetch(skipCount: _pageIndex++ * _itemsPerPage, takeCount: _itemsPerPage);

    @override
    dispose() {
        _scrollController.removeListener(_expandListOnScroll);

        super.dispose();
    }

    @override
    Widget build(BuildContext buildContext) {
        return new Scaffold(
            appBar: new AppBar(
                leading: new SettingsOpenerButton(),
                title: new Text('Language Cards'),
                actions: <Widget>[_editorMode ? _buildEditorDoneButton(): 
                    _buildEditorButton()]
            ),
            bottomNavigationBar: _editorMode ? _buildBottomBar(): null,
            drawer: new SettingsBlocProvider(child: new SettingsPanel()),
            body: _buildList(),
            floatingActionButton: _buildNewCardButton(buildContext)
        );
    }

    Widget _buildEditorButton() => new FlatButton(
        onPressed: () {
            setState(() => _editorMode = true);
        }, 
        child: new Text('Edit')
    );

    Widget _buildEditorDoneButton() => new FlatButton(
        onPressed: () {
            setState(() { 
                _itemsMarkedForRemovalInEditor.clear();
                _editorMode = false;
            });
        },
        child: new Text('Done')
    );

    Widget _buildBottomBar() {
        bool allSelected = _itemsMarkedForRemovalInEditor.length == _items.length;

        const int removalItemIndex = 0;
        final options = new List<BottomNavigationBarItem>.generate(2, (index) {
            if (index == removalItemIndex)
                return new BottomNavigationBarItem(
                    icon: new Icon(Icons.delete),
                    title: new Text('Remove')
                );
            else
                return new BottomNavigationBarItem(
                    icon: new Icon(Icons.select_all),
                    title: new Text('${allSelected ? 'Unselect': 'Select'} All')
                );
        });
        
        return new BottomNavigationBar(
            items: options,
            onTap: (tappedIndex) {
                if (tappedIndex == removalItemIndex) {
                    if (_itemsMarkedForRemovalInEditor.length == 0)
                        return;

                    _itemsMarkedForRemoval.addAll(_itemsMarkedForRemovalInEditor);

                    setState(() {
                        final idsMarkedForRemoval = _itemsMarkedForRemovalInEditor.keys;
                        _items.removeWhere((w) => idsMarkedForRemoval.contains(w.id));

                        _showItemRemovalInfoSnackBar(_scaffoldContext,
                            '${_itemsMarkedForRemovalInEditor.length} items have been removed',
                            _itemsMarkedForRemovalInEditor.keys.toList());

                        _itemsMarkedForRemovalInEditor.clear();
                    });
                }
                else {
                    if (allSelected)
                        setState(() => _itemsMarkedForRemovalInEditor.clear());
                    else {
                        setState(() {
                            int index = 0;
                            _items.forEach((w) =>
                                _itemsMarkedForRemovalInEditor[w.id] = new _CachedItem(w, index++));
                        });
                    }
                }
            }
        );
    }

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
        
        return new CheckboxListTile(
            value: _itemsMarkedForRemovalInEditor.containsKey(item.id),
            onChanged: (isChecked) {
                setState(() {
                    if (isChecked)
                        _itemsMarkedForRemovalInEditor[item.id] = new _CachedItem(item, itemIndex);
                    else
                        _itemsMarkedForRemovalInEditor.remove(item.id);
                });
            },
            title: _buildOneLineText(getItemTitle(item)),
            subtitle: _buildOneLineText(getItemSubtitle(item))
        );
    }

    @protected
    String getItemTitle(TItem item);

    @protected
    String getItemSubtitle(TItem item);

    Widget _buildOneLineText(String data) => 
        new Text(data, maxLines: 1, overflow: TextOverflow.ellipsis);

    Widget _buildDismissibleListItem(BuildContext buildContext, int itemIndex) {
        final item = _items[itemIndex];

        bool shouldRemove = false;
        return new Dismissible(
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
            child: new ListTile(
                title: _buildOneLineText(getItemTitle(item)),
                trailing: _buildOneLineText(getItemTrailing(item)),
                subtitle: _buildOneLineText(getItemSubtitle(item)),
                onTap: () => onLeaving(buildContext, item)
            )
        );
    }

    @protected
    String getItemTrailing(TItem item);

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

        _storage.remove(_getEntriesMarkedForRemoval(ids).map((entry) => entry.key).toList());
        _deleteFromMarkedForRemoval(ids);
    }

    Widget _buildNewCardButton(BuildContext buildContext) {
        final theme = Theme.of(buildContext);
        return new FloatingActionButton(
            onPressed: () => onLeaving(buildContext),
            child: new Icon(Icons.add_circle), 
            mini: true,
            tooltip: 'New Card',
            backgroundColor: (theme.floatingActionButtonTheme.backgroundColor ?? 
                theme.colorScheme.secondary).withOpacity(0.3)
        );
    }

    @mustCallSuper
    onLeaving(BuildContext buildContext, [TItem id]) {
        _deleteAllMarkedForRemoval();
    }
    
    _deleteAllMarkedForRemoval() {
        if (_itemsMarkedForRemoval.isEmpty)
            return;

        _storage.remove(_itemsMarkedForRemoval.keys);
        _itemsMarkedForRemoval.clear();
    }
}

abstract class ListScreen<TItem extends StoredEntity> extends StatefulWidget {
    final BaseStorage<TItem> storage;

    ListScreen({ this.storage });

    @override
    ListScreenState<TItem> createState();
}
