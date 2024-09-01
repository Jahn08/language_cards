import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import '../consts.dart';

abstract class InputKeyboard extends StatelessWidget
    with KeyboardCustomPanelMixin<String>
    implements PreferredSizeWidget {
  static const double _keyboardHeight = 270;

  final double _symbolSize;
  final ValueNotifier<String> _notifier;

  final List<String> symbols;

  final String Function(String? symbol) onSymbolTap;

  InputKeyboard(this.symbols,
      {required this.onSymbolTap,
      String? initialValue,
      super.key,
      double symbolSize = 15})
      : _symbolSize = symbolSize,
        _notifier = new ValueNotifier(initialValue ?? '');

  @override
  Widget build(BuildContext context) {
    const int rows = 4;
    const height = _keyboardHeight / (rows + 1) - 5;

    final itemsPerRow = ((symbols.length + 4) / rows).ceil();
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth / itemsPerRow;

    final children = symbols
        .map((s) => new _Key(
            symbol: new _SymbolButton(
                symbol: s,
                symbolSize: _symbolSize,
                onTap: () => updateValue(onSymbolTap(s))),
            height: height,
            width: width))
        .toList();

    final wideBtnWidth = width * 2;
    const backspaceColor = Colors.grey;
    const doneColor = Colors.blue;
    children.addAll([
      new _Key(
          symbol: new _Button(
              child: const Icon(Icons.backspace),
              color: backspaceColor,
              onTap: () => updateValue(onSymbolTap(null))),
          height: height,
          width: wideBtnWidth,
          borderColor: backspaceColor),
      new _Key(
          symbol: new _Button(
              child: const Icon(Icons.done),
              color: doneColor,
              onTap: () => FocusScope.of(context).unfocus()),
          height: height,
          width: wideBtnWidth,
          borderColor: doneColor)
    ]);

    return new Container(
        color: Colors.grey[300],
        height: _keyboardHeight,
        width: double.maxFinite,
        child: new Wrap(
            alignment: WrapAlignment.spaceEvenly,
            runAlignment: WrapAlignment.end,
            children: children));
  }

  @override
  ValueNotifier<String> get notifier => _notifier;

  @override
  Size get preferredSize => const Size.fromHeight(_keyboardHeight);
}

class _Key extends StatelessWidget {
  final Widget symbol;

  final double height;

  final double width;

  final Color? borderColor;

  const _Key(
      {required this.symbol,
      required this.height,
      required this.width,
      this.borderColor});

  @override
  Widget build(BuildContext context) => new Container(
      margin: const EdgeInsets.all(2),
      child: symbol,
      decoration: new BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(7)),
          border: Border.all(color: borderColor ?? Colors.grey[300]!),
          boxShadow: [
            new BoxShadow(color: Colors.grey[400]!, spreadRadius: 1)
          ]),
      width: width,
      height: height);
}

class _Button extends StatelessWidget {
  final Color? color;

  final Widget child;

  final void Function() onTap;

  const _Button({required this.child, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => new Material(
      color: color ?? Colors.grey[200],
      child: new InkWell(
          onTap: onTap, child: child, splashColor: Colors.grey[300]));
}

class _SymbolButton extends StatelessWidget {
  final String symbol;

  final double symbolSize;

  final void Function() onTap;

  const _SymbolButton(
      {required this.symbol, required this.symbolSize, required this.onTap});

  @override
  Widget build(BuildContext context) => new _Button(
      child: new Center(
          child: new Text(symbol,
              textAlign: TextAlign.center,
              style: new TextStyle(
                  color: Colors.black,
                  fontWeight: Consts.boldFontWeight,
                  fontSize: symbolSize))),
      onTap: onTap);
}
