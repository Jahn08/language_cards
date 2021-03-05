import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'styled_input_decoration.dart';

class _StyledTextFieldState extends State<StyledTextField> {
    FocusNode _focusNode;
    TextEditingController _controller;
    bool _isChanged = false;
    
    @override
    void initState() {
        super.initState();

        _controller = new TextEditingController(text: widget.initialValue);

        _focusNode = new FocusNode();
        _focusNode.addListener(_emitOnChangedEvent);
    }

    _emitOnChangedEvent() {
        if (!_focusNode.hasFocus && _isChanged)
            _emitOnChanged(_controller.text);
    }

    @override
    void didUpdateWidget(Widget oldWidget) {
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
		final locale = AppLocalizations.of(context);
        String tempValue = widget.initialValue;
        return new TextFormField(
            focusNode: _focusNode,
            readOnly: widget.readonly,
            keyboardType: TextInputType.text,
            decoration: new StyledInputDecoration(widget.label),
            autocorrect: true,
            onChanged: (val) {
                _isChanged = true;
                tempValue = val;
            },
            onEditingComplete: () {
                _emitOnChanged(tempValue, true);

                FocusScope.of(context).unfocus();
            },
            onSaved: _emitOnChanged,
            validator: (String text) {
                if (widget.isRequired && (text == null || text.isEmpty))
                    return locale.constsEmptyValueValidationError;

                return widget.validator?.call(text) ?? null;
            },
            controller: _controller
        );
    }

    void _emitOnChanged(String value, [bool isSubmitted]) {
        _isChanged = false;

        widget._onChanged?.call(value, isSubmitted ?? false);
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

    final Function(String, bool) _onChanged;

    final String initialValue;

	final String Function(String) validator;

    StyledTextField(this.label, { Key key, bool isRequired, 
        Function(String value, bool submitted) onChanged, bool readonly, 
		this.initialValue, this.validator }): 
        isRequired = isRequired ?? false,
        readonly = readonly ?? false,
        _onChanged = onChanged,
        super(key: key);

    @override
    State<StatefulWidget> createState() {
        return new _StyledTextFieldState();
    }
}
