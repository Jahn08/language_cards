import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class KeyboardActionsStateBottomed extends KeyboardActionstate {
    final FocusNode _focusNode;

    KeyboardActionsStateBottomed(FocusNode fieldFocusNode): _focusNode = fieldFocusNode, super() {
        _focusNode.addListener(() { 
            final bottom = WidgetsBinding.instance.window.viewInsets.bottom;
            final mainFocusNode = FocusScope.of(context);

            if (mainFocusNode.hasFocus && bottom > 0) {
                mainFocusNode.unfocus();

                new Timer(new Duration(milliseconds: 100), 
                    () => _focusNode.requestFocus());
            }
        });
    }
}

class KeyboardActionsBottomed extends KeyboardActions {
    final FocusNode _fieldFocusNode;

    KeyboardActionsBottomed({ 
        @required FocusNode fieldFocusNode,
        @required KeyboardActionsConfig config,
        Widget child
    }): _fieldFocusNode = fieldFocusNode, 
    super(child: child, config: config, disableScroll: true);

    @override
    KeyboardActionstate createState() {
        return new KeyboardActionsStateBottomed(_fieldFocusNode);
    }
}
