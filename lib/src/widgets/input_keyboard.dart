import 'package:flutter/material.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import '../consts.dart';

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

	List<String> get symbols => _symbols.toList();

    @override
    Widget build(BuildContext context) {
        const int rows = 4;
        final height = _keyboard_height / (rows + 1) - 5;

        final itemsPerRow = ((_symbols.length + 4) / rows).ceil();
        final screenWidth = MediaQuery.of(context).size.width;
        final width = screenWidth / itemsPerRow;

        final children = _symbols.map((s) => new _Key(
			symbol: new _SymbolButton(
				symbol: s,
				symbolSize: _symbolSize,
				onTap: () => updateValue((notifier.value ?? '') + s)
			), 
			height: height, 
			width: width
		)).toList();
        
        final wideBtnWidth = width * 2;
        final backspaceColor = Colors.grey;
        final doneColor = Colors.blue;
        children.addAll([
			new _Key(
				symbol: new _Button(
					child: new Icon(Icons.backspace), 
					color: backspaceColor, 
					onTap: () {
						final curValue = notifier.value ?? '';
						if (curValue.isNotEmpty) {
							final newValue = curValue.replaceFirst(_lastSymbolRegExp, '');
							updateValue(newValue == curValue ? 
								curValue.substring(0, curValue.length - 1): newValue);
						}
					}
				), 
				height: height, 
				width: wideBtnWidth, 
				borderColor: backspaceColor
			),
			new _Key(
				symbol: new _Button(
					child: new Icon(Icons.done), 
					color: doneColor,
					onTap: () => FocusScope.of(context).unfocus()
				), 
				height: height, 
				width: wideBtnWidth, 
				borderColor: doneColor
			)
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

    @override
    ValueNotifier<String> get notifier => _notifier;

    @override
    Size get preferredSize => new Size.fromHeight(_keyboard_height);
}

class _Key extends StatelessWidget {

	final Widget symbol;
	
	final double height;
	
	final double width;
	
	final Color borderColor; 	

	_Key({ @required this.symbol, @required this.height, @required this.width, this.borderColor });

	@override
	Widget build(BuildContext context) =>
        new Container(
            margin: new EdgeInsets.all(2),
            child: symbol,
            decoration: new BoxDecoration(
                borderRadius: new BorderRadius.all(new Radius.circular(7)),
                border: Border.all(
                    color: borderColor ?? Colors.grey[300], 
                    width: 1,
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

class _Button extends StatelessWidget {

	final Color color;

	final Widget child;

	final void Function() onTap;

	_Button({ @required this.child, @required this.onTap, this.color });

	@override
	Widget build(BuildContext context) =>
        new Material(
            color: color ?? Colors.grey[200],
            child: new InkWell(
                onTap: onTap,
                child: child,
                splashColor: Colors.grey[300]
            )
        );
}

class _SymbolButton extends StatelessWidget {
	
	final String symbol;

	final double symbolSize;

	final void Function() onTap;

	_SymbolButton({ @required this.symbol, @required this.symbolSize, @required this.onTap });

	@override
	Widget build(BuildContext context) =>
        new _Button(
			child: new Center(
				child: new Text(symbol, 
					textAlign: TextAlign.center,
					style: new TextStyle(
						color: Colors.black,
						fontWeight: Consts.boldFontWeight,
						fontSize: symbolSize
					))
			),
			onTap: onTap
		);
}
