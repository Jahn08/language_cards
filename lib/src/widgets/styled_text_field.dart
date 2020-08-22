import 'package:flutter/material.dart';
import './styled_form_field.dart';

class StyledTextField extends StyledFormField {
    final bool _isRequired; 
    final bool _readonly; 
    final FocusNode _focusNode; 
    final Function(String) _onChanged; 
    final String _initialValue; 

    StyledTextField(String hintText, 
        { Key key, bool isRequired, Function(String) onChanged, 
            String initialValue, bool readonly, FocusNode focusNode }): 
        _isRequired = isRequired ?? false,
        _readonly = readonly ?? false,
        _focusNode = focusNode,
        _onChanged = onChanged,
        _initialValue = initialValue,
        super(hintText, key: key);

    @override
    Widget build(BuildContext context) {
        String value;

        return new TextFormField(
            focusNode: _focusNode,
            readOnly: _readonly,
            keyboardType: TextInputType.text,
            decoration: super.decoration,
            autocorrect: true,
            onChanged: (val) => value = val,
            onEditingComplete: () => _onChanged?.call(value),
            validator: (String text) {
                if (_isRequired && (text == null || text.isEmpty))
                    return 'The field is required';

                return null;
            },
            controller: new TextEditingController(text: _initialValue),
            onFieldSubmitted: (_) => FocusScope.of(context).unfocus()
        );
    }
}
