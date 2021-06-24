import 'package:flutter/material.dart';
import 'selector_dialog.dart';
import '../utilities/styler.dart';
import '../widgets/dialog_list_view.dart';
import '../widgets/loader.dart';

abstract class SingleSelectorDialog<T> extends SelectorDialog<T> {
    final BuildContext _context;

    final String _title;
    
	final bool isShrunk;

    SingleSelectorDialog(BuildContext context, String title, { this.isShrunk }):
        _context = context,
        _title = title,
        super();

    Future<T> showAsync(Future<List<T>> futureItems) {
        return showDialog(
            context: _context,
            builder: (dialogContext) {
                return new FutureBuilder(
                    future: futureItems,
                    builder: (builderContext, AsyncSnapshot<List<T>> snapshot) {
                        if (!snapshot.hasData)
                            return _createDialogView([new Loader()]);
                        
                        return _buildDialog(snapshot.data);
                    }
                );
            }
        );
    }

    Widget _createDialogView(List<Widget> children, [List<Widget> buttons]) => 
		new DialogListView(
			isShrunk: isShrunk,
			title: new ListTile(
				title: new Text(_title, style: new Styler(_context).titleStyle)
			), 
			children: children,
			buttons: buttons
		);

    Widget _buildDialog(List<T> items) =>
		_createDialogView(items.map((w) => _buildDialogOption(w)).toList(), 
			[new Center(child: buildCancelBtn(_context))]);

    Widget _buildDialogOption(T item) => 
		new ShrinkableSimpleDialogOption(
			new ListTile(
				title: getItemTitle(item),
				subtitle: getItemSubtitle(item),
				trailing: getItemTrailing(item)
			), 
			onPressed: () => returnResult(_context, item),
			isShrunk: isShrunk
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
