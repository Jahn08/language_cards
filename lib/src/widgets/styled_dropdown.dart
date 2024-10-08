import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'styled_input_decoration.dart';

class StyledDropdown extends StatelessWidget {
  final String? label;
  final String? initialValue;

  final bool isRequired;

  final void Function(String?)? onChanged;
  final String? Function(String?)? onValidate;
  final List<String> options;

  StyledDropdown(Iterable<String> options,
      {super.key,
      bool? isRequired,
      this.onChanged,
      this.onValidate,
      this.initialValue,
      this.label})
      : options = options.toList()..sort(),
        isRequired = isRequired ?? false;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return new DropdownButtonFormField<String>(
        isExpanded: true,
        items: options
            .map((v) => new DropdownMenuItem(child: new Text(v), value: v))
            .toList(),
        onChanged: onChanged,
        decoration: new StyledInputDecoration(label),
        value: initialValue,
        validator: (String? text) {
          if (isRequired && (text == null || text.isEmpty))
            return locale!.constsEmptyValueValidationError;

          return onValidate?.call(text);
        });
  }
}
