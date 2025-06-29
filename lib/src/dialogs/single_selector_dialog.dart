import 'package:flutter/material.dart';
import 'selector_dialog.dart';
import '../utilities/styler.dart';
import '../widgets/cancel_button.dart';
import '../widgets/dialog_list_view.dart';
import '../widgets/loader.dart';
import '../widgets/one_line_text.dart';

abstract class SingleSelectorDialog<T> extends SelectorDialog<T> {
  @protected
  final BuildContext context;

  final String _title;

  final bool? isShrunk;

  const SingleSelectorDialog(this.context, String title, {this.isShrunk})
      : _title = title,
        super();

  Future<T?> showAsync(Future<List<T>> futureItems) {
    return showDialog(
        context: context,
        builder: (dialogContext) {
          return new FutureBuilder(
              future: futureItems,
              builder: (builderContext, AsyncSnapshot<List<T>> snapshot) {
                if (!snapshot.hasData)
                  return _createDialogView([const Loader()]);

                return _buildDialog(snapshot.data!, dialogContext);
              });
        });
  }

  Widget _createDialogView(List<Widget> children, [List<Widget>? buttons]) =>
      new DialogListView(
          isShrunk: isShrunk,
          title: new ListTile(
              title: new OneLineText(_title,
                  style: new Styler(context).titleStyle)),
          children: children,
          buttons: buttons);

  Widget _buildDialog(List<T> items, BuildContext inContext) =>
      _createDialogView(
          items.map((w) => _buildDialogOption(w, inContext)).toList(),
          [new Center(child: new CancelButton(() => returnResult(inContext)))]);

  Widget _buildDialogOption(T item, BuildContext inContext) =>
      new ShrinkableSimpleDialogOption(
          new ListTile(
              title: getItemTitle(item),
              subtitle: getItemSubtitle(item),
              trailing: getItemTrailing(item)),
          onPressed: () => returnResult(inContext, item),
          isShrunk: isShrunk);

  @override
  Future<T?> show([List<T>? items]) {
    items ??= <T>[];
    return items.isNotEmpty
        ? showDialog(
            context: context,
            builder: (BuildContext inContext) =>
                _buildDialog(items!, inContext))
        : Future.value();
  }

  @protected
  Widget getItemTitle(T item);

  @protected
  Widget getItemSubtitle(T item);

  @protected
  Widget? getItemTrailing(T item);
}
