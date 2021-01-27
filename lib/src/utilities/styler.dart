import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class Styler {

	final ThemeData theme;

	Styler(BuildContext context): theme = Theme.of(context);

	TextStyle get titleStyle => theme.textTheme.headline6;

	Color get primaryColor => theme.colorScheme.primary;

	Color get floatingActionButtonColor => 
		(theme.floatingActionButtonTheme.backgroundColor ?? theme.colorScheme.secondary)
			.withOpacity(0.4);
}
