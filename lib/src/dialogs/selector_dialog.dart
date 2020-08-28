import 'package:flutter/material.dart';

abstract class SelectorDialog<T> {
    @protected
    Widget buildCancelBtn(BuildContext context) => new RaisedButton(
        onPressed: () => returnResult(context),
        child: new Text('Cancel'),
        color: Colors.deepOrange[300]
    );

    @protected
    returnResult(BuildContext context, [T result]) => Navigator.pop(context, result);

    Future<T> show(List<T> items);
}
