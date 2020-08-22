import 'package:flutter/material.dart';
import './styled_form_field.dart';

class StyledDropdown extends StyledFormField {
    final String _initialValue;
    final Function(String) _onChanged;
    final List<String> _options;

    StyledDropdown(List<String> options, String hintText, 
        { Key key, Function(String) onChanged, String initialValue }):
        _initialValue = initialValue, 
        _onChanged = onChanged, 
        _options = options, 
        super(hintText, key: key);

    @override
    Widget build(BuildContext context) {
        return new DropdownButtonFormField<String>(
            items: _options.map((pos) => 
                new DropdownMenuItem(child: new Text(pos), value: pos)).toList(), 
            onChanged: _onChanged,
            decoration: super.decoration,
            value: _initialValue,
        );
    }
}
