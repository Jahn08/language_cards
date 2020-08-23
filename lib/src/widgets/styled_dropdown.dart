import 'package:flutter/material.dart';
import './styled_input_decoration.dart';

class StyledDropdown extends StatelessWidget {
    final String _hintText;
    final String _initialValue;
    final Function(String) _onChanged;
    final List<String> _options;

    StyledDropdown(List<String> options, String hintText, 
        { Key key, Function(String) onChanged, String initialValue }):
        _initialValue = initialValue, 
        _hintText = hintText, 
        _onChanged = onChanged, 
        _options = options,
        super(key: key);

    @override
    Widget build(BuildContext context) {
        return new DropdownButtonFormField<String>(
            items: _options.map((pos) => 
                new DropdownMenuItem(child: new Text(pos), value: pos)).toList(), 
            onChanged: _onChanged,
            decoration: new StyledInputDecoration(_hintText),
            value: _initialValue,
        );
    }
}
