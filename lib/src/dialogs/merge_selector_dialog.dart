import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:language_cards/src/data/word_storage.dart';
import 'single_selector_dialog.dart';

class MergeSelectorDialog extends SingleSelectorDialog<StoredWord> {

	final AppLocalizations _locale;

	final Map<int, String> _packNamesById;

	MergeSelectorDialog(BuildContext context, this._packNamesById): 
		_locale = AppLocalizations.of(context),
        super(context, AppLocalizations.of(context).mergeSelectorDialogTitle);

	@override
	Widget getItemTrailing(StoredWord item) => null;

	@override
	Widget getItemTitle(StoredWord item) => 
		new Text(_locale.mergeSelectorDialogWordTitle(
			item.text, item.partOfSpeech.present(_locale), _packNamesById[item.packId]));

	@override
	Widget getItemSubtitle(StoredWord item) => new Text(item.translation);
}
