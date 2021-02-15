import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'styled_input_decoration.dart';

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
		final locale = AppLocalizations.of(context);
        return new DropdownButtonFormField<String>(
            items: options.map((pos) => 
                new DropdownMenuItem(child: new Text(pos), value: pos)).toList(), 
            onChanged: onChanged,
            decoration: new StyledInputDecoration(label),
            value: initialValue,
            validator: (text) {
                if (isRequired && (text == null || text.isEmpty))
                    return locale.constsEmptyValueValidationError;

                return onValidate?.call(text);
            } 
        );
    }
}
