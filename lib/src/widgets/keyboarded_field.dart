import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import './keyboard_actions_bottomed.dart';
import './styled_input_decoration.dart';
import './input_keyboard.dart';

class KeyboardedField extends StatelessWidget {
    final String label;

    final FocusNode _focusNode;
    final InputKeyboard _keyboard;

    final String _initialValue;
    final Function(String) _onChanged;

    KeyboardedField(InputKeyboard keyboard, FocusNode focusNode, this.label,
        { Key key, Function(String) onChanged, String initialValue }): 
        _keyboard = keyboard,
        _initialValue = initialValue ?? '',
        _onChanged = onChanged,
        _focusNode = focusNode,
        super(key: key);

    @override
    Widget build(BuildContext context) {
        bool isInitialBuilding = true;
        final textFieldFocusNode = new FocusNode();
        
        return new KeyboardActionsBottomed(
            focusNode: _focusNode,
            config: _buildKeyboardConfig(),
            child: new Column(
                children: <Widget>[
                    new KeyboardCustomInput<String>(
                        focusNode: _focusNode,
                        builder: (BuildContext _context, String value, bool hasFocus) {
                            final curValue = isInitialBuilding ? _initialValue : (value ?? '');
                            if (!hasFocus && _initialValue != curValue)
                                new Timer(new Duration(), () => _emitOnChangedEvent(curValue));

                            if (isInitialBuilding)
                                isInitialBuilding = false;

                            if (hasFocus)
                                textFieldFocusNode.requestFocus();

                            return new TextFormField(
                                decoration: new StyledInputDecoration(label),
                                focusNode: textFieldFocusNode,
                                controller: new TextEditingController(text: curValue),
                                readOnly: true,
                                onSaved: (newValue) => _emitOnChangedEvent(newValue),
                                onEditingComplete: () => _emitOnChangedEvent(curValue)
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

    void _emitOnChangedEvent(String value) => _onChanged?.call(value);
}
