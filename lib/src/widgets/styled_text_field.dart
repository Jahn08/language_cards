import 'package:flutter/material.dart';
import './styled_input_decoration.dart';

class _StyledTextFieldState extends State<StyledTextField> {
    final bool _isRequired; 
    final bool _readonly; 
    final String _hintText; 
    final Function(String) _onChanged;

    String _tempValue;
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

        _addFocusListener();
    }

    void _addFocusListener() => _focusNode.addListener(_emitOnChangedEvent);

    FocusNode get _focusNode => this.widget.focusNode;

    _emitOnChangedEvent() {
        if (!_focusNode.hasFocus && _isChanged) {
            _isChanged = false;

            _onChanged?.call(_tempValue);
        }
    }

    @override
    void didUpdateWidget(Widget oldWidget) {
        _removeFocusListener(focusNode: (oldWidget as StyledTextField).focusNode);
        _addFocusListener();
    
        super.didUpdateWidget(oldWidget);
    }

    void _removeFocusListener({ FocusNode focusNode }) => 
        (focusNode ?? _focusNode).removeListener(_emitOnChangedEvent);

    @override
    Widget build(BuildContext context) {
        _tempValue = widget.initialValue;
        return new TextFormField(
            focusNode: _focusNode,
            readOnly: _readonly,
            keyboardType: TextInputType.text,
            decoration: new StyledInputDecoration(_hintText),
            autocorrect: true,
            onChanged: (val) {
                _isChanged = true;
                _tempValue = val;
            },
            onEditingComplete: () {
                _isChanged = false;

                _onChanged?.call(_tempValue);
                FocusScope.of(context).unfocus();
            },
            validator: (String text) {
                if (_isRequired && (text == null || text.isEmpty))
                    return 'The field is required';

                return null;
            },
            controller: new TextEditingController(text: _tempValue)
        );
    }

    @override
    void dispose() {
        _removeFocusListener();
        
        super.dispose();
    }
}

class StyledTextField extends StatefulWidget {
    final bool _isRequired; 
    final bool _readonly; 
    final String _hintText; 

    final Function(String) _onChanged;

    final String initialValue; 
    final FocusNode focusNode; 

    StyledTextField(String hintText, { Key key, bool isRequired, Function(String) onChanged,
        bool readonly, FocusNode focusNode, this.initialValue }): 
        focusNode = focusNode ?? new FocusNode(),
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
