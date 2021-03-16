import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Consts {

    Consts._();

    static const IconData cardListIcon = Icons.filter_1;

    static String getSelectorLabel(bool allSelected, AppLocalizations locale) => 
		allSelected ? locale.constsUnselectAll: locale.constsSelectAll;

	static const double largeFontSize = 20;

	static const FontWeight boldFontWeight = FontWeight.w800;
}
