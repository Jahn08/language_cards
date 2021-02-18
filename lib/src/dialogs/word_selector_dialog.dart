import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'single_selector_dialog.dart';
import '../models/word.dart';

class WordSelectorDialog extends SingleSelectorDialog<Word> {

	final BuildContext context;

    WordSelectorDialog(this.context):
        super(context, AppLocalizations.of(context).wordSelectorDialogTitle);
   
    @override
    Widget getItemSubtitle(Word item) => 
		new Text(item.partOfSpeech.present(AppLocalizations.of(context)));
  
    @override
    String getItemTitle(Word item) => item.translations.join('; ');

    @override
    Widget getItemTrailing(Word item) => null;
}
