import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NoTranslationSnackBar {
  NoTranslationSnackBar._();

  static void show(BuildContext scaffoldContext, [AppLocalizations? locale]) {
    locale ??= AppLocalizations.of(scaffoldContext)!;
    ScaffoldMessenger.of(scaffoldContext).showSnackBar(
        new SnackBar(content: new Text(locale.noTranslationSnackBarInfo)));
  }
}
