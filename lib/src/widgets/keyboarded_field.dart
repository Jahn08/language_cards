import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import './keyboard_actions_bottomed.dart';
import './styled_text_field.dart';
import './input_keyboard.dart';

class KeyboardedField extends StatelessWidget {
    final String _hintText;
    final String _initialValue;
    final Function(String) _onChanged;

    final FocusNode _focusNode = new FocusNode(canRequestFocus: true, skipTraversal: false);
    final InputKeyboard _keyboard;

    KeyboardedField(InputKeyboard keyboard, String hintText, 
        { Key key, Function(String) onChanged, String initialValue }): 
        _keyboard = keyboard,
        _hintText = hintText,
        _initialValue = initialValue,
        _onChanged = onChanged,
        super(key: key);

    @override
    Widget build(BuildContext context) {
        final textFieldFocusNode = new FocusNode();

        return new KeyboardActionsBottomed(
            fieldFocusNode: textFieldFocusNode,
            config: _buildKeyboardConfig(),
            child: new Column(
                children: <Widget>[
                    new KeyboardCustomInput<String>(
                        focusNode: _focusNode,
                        builder: (BuildContext _context, String value, bool hasFocus) =>
                            new StyledTextField(
                                _hintText, 
                                focusNode: textFieldFocusNode,
                                initialValue: value?.isEmpty == true ? _initialValue : value,
                                readonly: true,
                                onChanged: _onChanged
                            ), 
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
