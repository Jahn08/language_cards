import 'package:flutter/material.dart';
import './styled_input_decoration.dart';

class StyledDropdown extends StatelessWidget {
    final String label;
    final String initialValue;
    
    final bool isRequired;

    final Function(String) onChanged;
    final Function(String) onValidate;
    final Iterable<String> options;

    StyledDropdown(this.options, { Key key, bool isRequired, this.onChanged, 
        this.onValidate, this.initialValue, this.label }):
        isRequired = isRequired ?? false,
        super(key: key);

    @override
    Widget build(BuildContext context) {
        return new DropdownButtonFormField<String>(
            items: options.map((pos) => 
                new DropdownMenuItem(child: new Text(pos), value: pos)).toList(), 
            onChanged: onChanged,
            decoration: new StyledInputDecoration(label),
            value: initialValue,
            validator: (text) {
                if (isRequired && (text == null || text.isEmpty))
                    return 'The field cannot be empty';

                return onValidate?.call(text);
            } 
        );
    }
}
