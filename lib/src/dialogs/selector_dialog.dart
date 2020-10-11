import 'package:flutter/material.dart';
import './outcome_dialog.dart';

abstract class SelectorDialog<T> extends OutcomeDialog<T> {
    @protected
    Widget buildCancelBtn(BuildContext context) => new RaisedButton(
        onPressed: () => returnResult(context),
        child: new Text('Cancel'),
        color: Colors.deepOrange[300]
    );

    Future<T> show(List<T> items);
}
