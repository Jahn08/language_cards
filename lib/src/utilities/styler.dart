import 'package:flutter/material.dart';

class Styler {
  final BuildContext context;

  ThemeData? _theme;

  MediaQueryData? _media;

  Styler(this.context);

  ThemeData get theme => _theme ?? (_theme = Theme.of(context));

  TextStyle? get titleStyle => theme.textTheme.titleLarge;

  Color get primaryColor => theme.colorScheme.primary;

  Color get dividerColor => theme.dividerColor;

  Color get floatingActionButtonColor =>
      (theme.floatingActionButtonTheme.backgroundColor ??
              theme.colorScheme.secondary)
          .withOpacity(0.4);

  bool get isDense => _isDense(_media ?? (_media = MediaQuery.of(context)));

  static bool _isDense(MediaQueryData data) => data.size.shortestSide <= 600;

  bool get isWindowDense => _isDense(MediaQueryData.fromView(View.of(context)));
}
