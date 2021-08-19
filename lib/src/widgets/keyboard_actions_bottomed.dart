import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class _KeyboardActionsStateBottomed extends KeyboardActionstate {
    FocusNode _focusNode;

    _KeyboardActionsStateBottomed(FocusNode focusNode): 
        _focusNode = focusNode, super() {
            assert(_focusNode != null);
        }

    @override
    void initState() {
        super.initState();

        _addFocusListener();
    }

    void _addFocusListener() => _focusNode.addListener(_stickToBottom);

    void _stickToBottom() {
        final bottom = WidgetsBinding.instance.window.viewInsets.bottom;
        final mainFocusNode = FocusScope.of(context);

        if (mainFocusNode.hasFocus && bottom > 0) {
            mainFocusNode.unfocus();

            new Timer(new Duration(milliseconds: 100), 
                () => _focusNode.requestFocus());
        }
    }

    @protected
	@override
    void didUpdateWidget(KeyboardActions oldWidget) {
        super.didUpdateWidget(oldWidget);

        _removeFocusListener();

        _focusNode = (widget as KeyboardActionsBottomed).focusNode;
        _addFocusListener();
    }

    void _removeFocusListener() => _focusNode.removeListener(_stickToBottom);

    @override
    void dispose() {
        _removeFocusListener();

        super.dispose();
    }
}

class KeyboardActionsBottomed extends KeyboardActions {
    final FocusNode focusNode;

    KeyboardActionsBottomed({ 
        @required this.focusNode,
        @required KeyboardActionsConfig config,
        Widget child
    }): super(child: child, config: config, disableScroll: true);

    @override
    KeyboardActionstate createState() {
        return new _KeyboardActionsStateBottomed(focusNode);
    }
}
