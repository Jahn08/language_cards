import 'package:flutter/material.dart';
import './outcome_dialog.dart';

abstract class CancellableDialog<TResult> extends OutcomeDialog<TResult> {

    static const String cancellationLabel = 'Cancel';

    @protected
    Widget buildCancelBtn(BuildContext context, [TResult result]) => new RaisedButton(
        onPressed: () => returnResult(context, result),
        child: new Text(cancellationLabel),
        color: Colors.deepOrange[300]
    );
}
