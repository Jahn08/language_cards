import 'package:flutter/material.dart';
import './styled_input_decoration.dart';

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
        String tempValue = widget.initialValue;
        return new TextFormField(
            focusNode: _focusNode,
            readOnly: widget._readonly,
            keyboardType: TextInputType.text,
            decoration: new StyledInputDecoration(widget._hintText),
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
                if (widget._isRequired && (text == null || text.isEmpty))
                    return 'The field cannot be empty';

                return null;
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
    final bool _isRequired; 
    final bool _readonly; 
    final String _hintText; 

    final Function(String, bool) _onChanged;

    final String initialValue;

    StyledTextField(String hintText, { Key key, bool isRequired, 
        Function(String value, bool submitted) onChanged, bool readonly, this.initialValue }): 
        _isRequired = isRequired ?? false,
        _readonly = readonly ?? false,
        _onChanged = onChanged,
        _hintText = hintText,
        super(key: key);

    @override
    State<StatefulWidget> createState() {
        return new _StyledTextFieldState();
    }
}
