import 'package:flutter/material.dart';
import './outcome_dialog.dart';

abstract class CancellableDialog<TResult> extends OutcomeDialog<TResult> {
    @protected
    Widget buildCancelBtn(BuildContext context) => new RaisedButton(
        onPressed: () => returnResult(context),
        child: new Text('Cancel'),
        color: Colors.deepOrange[300]
    );
}
