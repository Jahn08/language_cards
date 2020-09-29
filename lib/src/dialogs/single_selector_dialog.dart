import 'package:flutter/material.dart';
import './selector_dialog.dart';
import '../widgets/loader.dart';

abstract class SingleSelectorDialog<T> extends SelectorDialog<T> {
    final BuildContext _context;

    final String _title;
    
    SingleSelectorDialog(BuildContext context, String title):
        _context = context,
        _title = title ?? 'Choose an item',
        super();

    Future<T> showAsync(Future<List<T>> futureItems) {
        return showDialog(
            context: _context,
            builder: (dialogContext) {
                return new FutureBuilder(
                    future: futureItems,
                    builder: (builderContext, AsyncSnapshot<List<T>> snapshot) {
                        if (!snapshot.hasData)
                            return _createSimpleDialog([new Loader()]);
                        
                        return _buildDialog(snapshot.data);
                    }
                );
            }
        );
    }

    Widget _createSimpleDialog(List<Widget> children) => new SimpleDialog(
        title: new Text(_title),
        children: children
    );

    Widget _buildDialog(List<T> items) {
        final children = items.map((w) => _buildDialogOption(w)).toList();
        children.add(new Center(child: buildCancelBtn(_context)));

        return _createSimpleDialog(children);
    }

    @override
    Future<T> show(List<T> items) {
        items = items ?? <T>[];
        return items.length > 0 ? showDialog(
            context: _context,
            builder: (_) => _buildDialog(items)
        ) : Future.value(null);
    } 

    Widget _buildDialogOption(T item) => new SimpleDialogOption(
        onPressed: () => returnResult(_context, item),
        child: new ListTile(
            title: new Text(getItemTitle(item)),
            subtitle: new Text(getItemSubtitle(item))
        )
    );

    @protected
    String getItemTitle(T item);

    @protected
    String getItemSubtitle(T item);
}
