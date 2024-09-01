import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'styled_input_decoration.dart';

class _StyledTextFieldState extends State<StyledTextField> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _isChanged = false;

  @override
  void initState() {
    super.initState();

    _controller = new TextEditingController(text: widget.initialValue);

    _focusNode = new FocusNode();
    _focusNode.addListener(_emitOnChangedEvent);
  }

  void _emitOnChangedEvent() {
    widget.onFocusChanged?.call(hasFocus: _focusNode.hasFocus);

    if (!_focusNode.hasFocus && _isChanged) _emitOnChanged(_controller.text);
  }

  @override
  void didUpdateWidget(StyledTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_controller.text != widget.initialValue) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.text = widget.initialValue;
        _controller.clearComposing();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    String? tempValue = widget.initialValue;
    return new TextFormField(
        focusNode: _focusNode,
        readOnly: widget.readonly,
        keyboardType: widget.enableSuggestions
            ? TextInputType.text
            : TextInputType.visiblePassword,
        decoration: new StyledInputDecoration(widget.label),
        onChanged: (val) {
          _isChanged = true;
          tempValue = val;

          widget.onInput?.call(val);
        },
        onEditingComplete: () {
          _emitOnChanged(tempValue, submitted: true);

          FocusScope.of(context).unfocus();
        },
        onSaved: _emitOnChanged,
        validator: (String? text) {
          if (widget.isRequired && (text == null || text.isEmpty))
            return locale.constsEmptyValueValidationError;

          return widget.validator?.call(text);
        },
        controller: _controller);
  }

  void _emitOnChanged(String? value, {bool submitted = false}) {
    _isChanged = false;

    widget._onChanged?.call(value, submitted: submitted);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_emitOnChangedEvent);

    _controller.dispose();

    super.dispose();
  }
}

class StyledTextField extends StatefulWidget {
  final bool isRequired;
  final bool readonly;

  final String label;

  final void Function(String?, {bool? submitted})? _onChanged;

  final Function(String)? onInput;

  final Function({bool hasFocus})? onFocusChanged;

  final String initialValue;

  final String? Function(String?)? validator;

  final bool enableSuggestions;

  const StyledTextField(this.label,
      {Key? key,
      this.isRequired = false,
      void Function(String? value, {bool? submitted})? onChanged,
      this.readonly = false,
      this.initialValue = '',
      this.validator,
      this.enableSuggestions = true,
      this.onInput,
      this.onFocusChanged})
      : _onChanged = onChanged,
        super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new _StyledTextFieldState();
  }
}
