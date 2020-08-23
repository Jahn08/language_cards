import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import './keyboard_actions_bottomed.dart';
import './styled_input_decoration.dart';
import './input_keyboard.dart';

class KeyboardedField extends StatelessWidget {
    final String _hintText;
    final FocusNode _focusNode;
    final InputKeyboard _keyboard;

    final String _initialValue;
    final Function(String) _onChanged;

    KeyboardedField(InputKeyboard keyboard, String hintText, FocusNode focusNode,
        { Key key, Function(String) onChanged, String initialValue }): 
        _keyboard = keyboard,
        _hintText = hintText,
        _initialValue = initialValue ?? '',
        _onChanged = onChanged,
        _focusNode = focusNode,
        super(key: key);

    @override
    Widget build(BuildContext context) {
        bool isInitialBuilding = true;
        final textFieldFocusNode = new FocusNode();
        
        return new KeyboardActionsBottomed(
            fieldFocusNode: textFieldFocusNode,
            config: _buildKeyboardConfig(),
            child: new Column(
                children: <Widget>[
                    new KeyboardCustomInput<String>(
                        focusNode: _focusNode,
                        builder: (BuildContext _context, String value, bool hasFocus) {
                            final curValue = isInitialBuilding ? _initialValue : (value ?? '');
                            if (!hasFocus && _initialValue != curValue)
                                new Timer(new Duration(), () => _onChanged?.call(curValue));

                            if (isInitialBuilding)
                                isInitialBuilding = false;

                            return new TextFormField(
                                decoration: new StyledInputDecoration(_hintText),
                                focusNode: textFieldFocusNode,
                                controller: new TextEditingController(text: curValue),
                                readOnly: true,
                                onEditingComplete: () => _onChanged(curValue),
                            );
                        }, 
                        notifier: _keyboard.notifier
                    )
                ]
            )
        );
    }

    KeyboardActionsConfig _buildKeyboardConfig() {
        return new KeyboardActionsConfig(
            keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
            actions: <KeyboardActionsItem>[
                new KeyboardActionsItem(
                    displayArrows: false,
                    displayActionBar: false,
                    focusNode: _focusNode, 
                    footerBuilder: (context) => _keyboard
                )
            ]
        );
    }
}
