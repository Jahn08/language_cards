import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Styler {

	final BuildContext context;

	ThemeData _theme;

	MediaQueryData _media;

	Styler(this.context);
	
	ThemeData get theme => _theme ?? (_theme = Theme.of(context));

	TextStyle get titleStyle => theme.textTheme.headline6;

	Color get primaryColor => theme.colorScheme.primary;

	Color get dividerColor => theme.dividerColor;

	Color get floatingActionButtonColor => 
		(theme.floatingActionButtonTheme.backgroundColor ?? theme.colorScheme.secondary)
			.withOpacity(0.4);

	bool get isDense => _isDense(_media ?? (_media = MediaQuery.of(context)));

	static bool _isDense(MediaQueryData data) => data.size.shortestSide <= 600;

	static bool get isWindowDense => 
		_isDense(MediaQueryData.fromWindow(WidgetsBinding.instance.window));
}
