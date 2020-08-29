import 'package:flutter/material.dart';
import './styled_input_decoration.dart';

class _StyledTextFieldState extends State<StyledTextField> {
    final bool _isRequired; 
    final bool _readonly; 
    final String _hintText; 
    final Function(String) _onChanged;

    FocusNode _focusNode;
    TextEditingController _controller;
    bool _isChanged = false;
    
    _StyledTextFieldState(String hintText, { bool isRequired, 
        Function(String) onChanged, bool readonly }): 
        _isRequired = isRequired ?? false,
        _readonly = readonly ?? false,
        _onChanged = onChanged,
        _hintText = hintText,
        super();

    @override
    void initState() {
        super.initState();

        _controller = new TextEditingController(text: widget.initialValue);

        _focusNode = new FocusNode();
        _focusNode.addListener(_emitOnChangedEvent);
    }

    _emitOnChangedEvent() {
        if (!_focusNode.hasFocus && _isChanged) {
            _isChanged = false;

            _onChanged?.call(_controller.text);
        }
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
            readOnly: _readonly,
            keyboardType: TextInputType.text,
            decoration: new StyledInputDecoration(_hintText),
            autocorrect: true,
            onChanged: (val) {
                _isChanged = true;
                tempValue = val;
            },
            onEditingComplete: () {
                _isChanged = false;

                _onChanged?.call(tempValue);
                FocusScope.of(context).unfocus();
            },
            validator: (String text) {
                if (_isRequired && (text == null || text.isEmpty))
                    return 'The field is required';

                return null;
            },
            controller: _controller
        );
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

    final Function(String) _onChanged;

    final String initialValue;

    StyledTextField(String hintText, { Key key, bool isRequired, Function(String) onChanged,
        bool readonly, this.initialValue }): 
        _isRequired = isRequired ?? false,
        _readonly = readonly ?? false,
        _onChanged = onChanged,
        _hintText = hintText,
        super(key: key);

    @override
    State<StatefulWidget> createState() {
        return new _StyledTextFieldState(_hintText, isRequired: _isRequired,
            onChanged: _onChanged, readonly: _readonly);
    }
}
