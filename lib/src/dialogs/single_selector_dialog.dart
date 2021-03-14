import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'selector_dialog.dart';
import '../widgets/loader.dart';

abstract class SingleSelectorDialog<T> extends SelectorDialog<T> {
    final BuildContext _context;

    final String _title;
    
    SingleSelectorDialog(BuildContext context, String title):
        _context = context,
        _title = title ?? AppLocalizations.of(context).singleSelectorDialogTitle,
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

    Widget _createSimpleDialog(List<Widget> children) => new Scrollbar(
        child: new SimpleDialog(
            title: new Text(_title),
            children: children
        )
    );

    Widget _buildDialog(List<T> items) {
        final children = items.map((w) => _buildDialogOption(w)).toList();
        children.add(new Center(child: buildCancelBtn(_context)));

        return _createSimpleDialog(children);
    }

    Widget _buildDialogOption(T item) => new SimpleDialogOption(
        onPressed: () => returnResult(_context, item),
        child: new ListTile(
            title: getItemTitle(item),
            subtitle: getItemSubtitle(item),
            trailing: getItemTrailing(item)
        )
    );

    @override
    Future<T> show(List<T> items) {
        items = items ?? <T>[];
        return items.length > 0 ? showDialog(
            context: _context,
            builder: (_) => _buildDialog(items)
        ) : Future.value(null);
    } 

    @protected
    Widget getItemTitle(T item);

    @protected
    Widget getItemSubtitle(T item);

    @protected
    Widget getItemTrailing(T item);
}
