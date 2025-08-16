import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:language_cards/src/models/language.dart';
import './input_keyboard.dart';
import './keyboard_actions_bottomed.dart';
import './phonetic_keyboard.dart';
import './styled_input_decoration.dart';

class KeyboardedField extends StatelessWidget {
  final String label;

  final FocusNode _focusNode;

  final Language? _lang;
  final String _initialValue;
  final Function(String)? _onChanged;

  const KeyboardedField(Language? lang, FocusNode focusNode, this.label,
      {super.key, Function(String)? onChanged, String? initialValue})
      : _lang = lang,
        _initialValue = initialValue ?? '',
        _onChanged = onChanged,
        _focusNode = focusNode;

  @override
  Widget build(BuildContext context) {
    bool isInitialBuilding = true;
    final textFieldFocusNode = new FocusNode();

    late TextEditingController textController;
    int? newPosition;
    late RegExp lastSymbolRegExp;

    final screenSize = MediaQuery.of(context).size;
    final keyboardSize = new Size(screenSize.width, screenSize.height * 0.4);

    final keyboard = PhoneticKeyboard.getLanguageSpecific((symbol) {
      final selection = textController.selection;
      final isNormalized = selection.isNormalized;
      final curPosition = isNormalized ? selection.start : selection.end;
      final endPosition = isNormalized ? selection.end : selection.start;

      final text = textController.text;

      String? newText;
      newPosition = curPosition;
      if (symbol == null) {
        if (text.isNotEmpty) {
          if (!selection.isCollapsed)
            newText =
                text.substring(0, curPosition) + text.substring(endPosition);
          else if (curPosition > 0) {
            newText = text
                    .substring(0, curPosition)
                    .replaceFirst(lastSymbolRegExp, '') +
                text.substring(curPosition);
            newPosition = curPosition + (newText.length - text.length);
          }
        }

        newText ??= text;
      } else {
        newText = curPosition == text.length
            ? text + symbol
            : text.substring(0, curPosition) +
                symbol +
                text.substring(endPosition);
        newPosition = curPosition + symbol.length;
      }

      return newText;
    }, height: keyboardSize.height, initialValue: _initialValue, lang: _lang);
    lastSymbolRegExp = new RegExp('(${keyboard.symbols.join('|')}|.)\$');

    return new KeyboardActionsBottomed(
        focusNode: _focusNode,
        config: _buildKeyboardConfig(keyboard, keyboardSize),
        child: new Column(children: <Widget>[
          new KeyboardCustomInput<String?>(
              focusNode: _focusNode,
              builder: (BuildContext context, String? value, bool? hasFocus) {
                final inHasFocus = hasFocus ?? false;
                final curValue =
                    isInitialBuilding ? _initialValue : (value ?? '');
                if (!inHasFocus && _initialValue != curValue)
                  new Timer(Duration.zero, () => _emitOnChangedEvent(curValue));

                if (isInitialBuilding) isInitialBuilding = false;

                if (inHasFocus) textFieldFocusNode.requestFocus();

                textController = new TextEditingController(text: curValue);
                textController.selection = new TextSelection.fromPosition(
                    new TextPosition(offset: newPosition ?? curValue.length));
                return new TextFormField(
                    decoration: new StyledInputDecoration(label),
                    focusNode: textFieldFocusNode,
                    controller: textController,
                    readOnly: true,
                    showCursor: true,
                    onSaved: (newValue) => _emitOnChangedEvent(newValue ?? ''),
                    onEditingComplete: () => _emitOnChangedEvent(curValue));
              },
              notifier: keyboard.notifier)
        ]));
  }

  KeyboardActionsConfig _buildKeyboardConfig(
          InputKeyboard keyboard, Size keyboardSize) =>
      new KeyboardActionsConfig(actions: <KeyboardActionsItem>[
        new KeyboardActionsItem(
            displayArrows: false,
            displayActionBar: false,
            focusNode: _focusNode,
            footerBuilder: (context) => _PreferredSizePadding(
                child: keyboard, preferredSize: keyboardSize))
      ]);

  void _emitOnChangedEvent(String value) => _onChanged?.call(value);
}

class _PreferredSizePadding extends StatelessWidget
    implements PreferredSizeWidget {
  final Widget child;
  @override
  final Size preferredSize;

  const _PreferredSizePadding({
    required this.child,
    required this.preferredSize,
  });

  @override
  Widget build(BuildContext context) {
    return new Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: child);
  }
}
