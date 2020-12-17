import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';

abstract class InputKeyboard extends StatelessWidget with KeyboardCustomPanelMixin<String>
    implements PreferredSizeWidget {
    static const double _keyboard_height = 270;

    final List<String> _symbols;
    final double _symbolSize;
    final ValueNotifier<String> _notifier;

    final RegExp _lastSymbolRegExp;

    InputKeyboard(List<String> symbols, double symbolSize, { Key key, String initialValue }): 
        _symbols = symbols,
        _symbolSize = symbolSize,
        _lastSymbolRegExp = new RegExp('(${symbols.join('|')})\$'),
        _notifier = new ValueNotifier(initialValue ?? ''),
        super(key: key);

    @override
    Widget build(BuildContext context) {
        const int rows = 4;
        final height = _keyboard_height / (rows + 1) - 5;

        final itemsPerRow = ((_symbols.length + 4) / rows).ceil();
        final screenWidth = MediaQuery.of(context).size.width;
        final width = screenWidth / itemsPerRow;

        final children = _symbols.map((s) => _buildKey(_buildSymbolButton(s), height, width))
            .toList();
        
        final wideBtnWidth = width * 2;
        children.addAll([
            _buildBackspaceKey(height, wideBtnWidth),
            _buildDoneKey(context, height, wideBtnWidth)
        ]);

        return new Container(
            color: Colors.grey[300],
            height: _keyboard_height,
            width: double.maxFinite,
            child: new Wrap(
                alignment: WrapAlignment.spaceEvenly,
                runAlignment: WrapAlignment.end,
                children: children
            )
        ); 
    }

    Widget _buildSymbolButton(String symbol) {
        return _buildButton(new Center(
            child: new Text(symbol, 
                textAlign: TextAlign.center,
                style: new TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w800,
                    fontSize: _symbolSize
                )
            )
        ), onTap: () => updateValue((notifier.value ?? '') + symbol));
    }

    Widget _buildButton(Widget content, { Color color, Function() onTap }) {
        return new Material(
            color: color ?? Colors.grey[200],
            child: new InkWell(
                onTap: onTap,
                child: content,
                splashColor: Colors.grey[300]
            )
        );
    }

    Widget _buildKey(Widget symbol, double height, double width, { Color borderColor }) {
        return new Container(
            margin: new EdgeInsets.all(2),
            child: symbol,
            decoration: new BoxDecoration(
                borderRadius: new BorderRadius.all(new Radius.circular(10)),
                border: Border.all(
                    color: borderColor ?? Colors.grey[300], 
                    width: 5,
                    style: BorderStyle.solid
                ),
                boxShadow: [
                    new BoxShadow(
                        color: Colors.grey[400], 
                        spreadRadius: 1
                    )
                ]
            ),
            width: width,
            height: height
        ); 
    }

    Widget _buildBackspaceKey(double height, double width) {
        final fillingColor = Colors.grey;
        return _buildKey(_buildButton(new Icon(Icons.backspace), 
            color: fillingColor, 
            onTap: () {
                final curValue = notifier.value ?? '';
                if (curValue.isNotEmpty)
                    updateValue(curValue.replaceFirst(_lastSymbolRegExp, ''));
            }
        ), height, width, borderColor: fillingColor);
    }

    Widget _buildDoneKey(BuildContext context, double height, double width) {
        final fillingColor = Colors.blue;
        return _buildKey(
            _buildButton(new Icon(Icons.done), 
            color: fillingColor,
            onTap: () => FocusScope.of(context).unfocus()
        ), height, width, borderColor: fillingColor);
    }

    @override
    ValueNotifier<String> get notifier => _notifier;

    @override
    Size get preferredSize => new Size.fromHeight(_keyboard_height);
}
