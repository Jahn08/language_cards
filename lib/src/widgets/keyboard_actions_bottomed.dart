import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

class _KeyboardActionsStateBottomed extends KeyboardActionstate {
  late FocusNode _focusNode;

  _KeyboardActionsStateBottomed() : super();

  @override
  void initState() {
    super.initState();

    _addFocusListener(_setFocusNode());
  }

  FocusNode _setFocusNode() =>
      _focusNode = (widget as KeyboardActionsBottomed).focusNode;

  void _addFocusListener(FocusNode nodeToListen) =>
      nodeToListen.addListener(_stickToBottom);

  void _stickToBottom() {
    final bottom = View.of(context).viewInsets.bottom;
    final mainFocusNode = FocusScope.of(context);

    if (mainFocusNode.hasFocus && bottom > 0) {
      mainFocusNode.unfocus();

      new Timer(
          const Duration(milliseconds: 100), () => _focusNode.requestFocus());
    }
  }

  @protected
  @override
  void didUpdateWidget(KeyboardActionsBottomed oldWidget) {
    super.didUpdateWidget(oldWidget);

    _removeFocusListener(_focusNode);
    _addFocusListener(_setFocusNode());
  }

  void _removeFocusListener(FocusNode nodeToUnlisten) =>
      nodeToUnlisten.removeListener(_stickToBottom);

  @override
  void dispose() {
    _removeFocusListener(_focusNode);

    super.dispose();
  }
}

class KeyboardActionsBottomed extends KeyboardActions {
  final FocusNode focusNode;

  const KeyboardActionsBottomed(
      {required this.focusNode,
      required KeyboardActionsConfig config,
      Widget? child})
      : super(child: child, config: config, disableScroll: true);

  @override
  _KeyboardActionsStateBottomed createState() =>
      new _KeyboardActionsStateBottomed();
}
