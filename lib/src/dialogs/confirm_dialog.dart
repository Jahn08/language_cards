import 'package:flutter/material.dart';
import './outcome_dialog.dart';

class ConfirmDialog<TResult> extends OutcomeDialog<TResult> {
    
    static const Map<bool, String> okActions = const { true: 'OK' };

    final String title;

    final String content;

    final Map<TResult, String> _actions;

    ConfirmDialog({ @required this.title, @required this.content, 
        @required Map<TResult, String> actions }):
        _actions = actions ?? new Map<TResult, String>();

    static ConfirmDialog<bool> buildOkDialog({ @required String title, @required String content }) =>
        ConfirmDialog<bool>(title: title, content: content, actions: okActions);

    Future<TResult> show(BuildContext context) async {
        if (_actions.length == 0)
            return null;

        return await showDialog(
            context: context, 
            builder: (buildContext) => new AlertDialog(
                content: new Text(content),
                title: new Text(title),
                actions: _actions.entries.map((entry) => 
                    new FlatButton(child: new Text(entry.value), 
                        onPressed: () => Navigator.pop(buildContext, entry.key))).toList()
            )
        );
    }
}
