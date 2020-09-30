import 'package:flutter/material.dart';
import '../models/word.dart';
import './single_selector_dialog.dart';

class WordSelectorDialog extends SingleSelectorDialog<Word> {
    WordSelectorDialog(BuildContext context):
        super(context, 'Choose a word definition');
   
    @override
    String getItemSubtitle(Word item) => item.partOfSpeech;
  
    @override
    String getItemTitle(Word item) => item.translations.join('; ');

    @override
    Widget getItemTrailing(Word item) => null;
}
