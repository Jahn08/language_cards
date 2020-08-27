import 'package:flutter/material.dart';
import '../models/word.dart';

class WordSelectorDialog {
    
    WordSelectorDialog._();

    static Future<Word> show(List<Word> words, BuildContext context) {
        words = words ?? <Word>[];
        return words.length > 0 ? showDialog(
            context: context,
            builder: (dialogContext) {
                final children = words.map((w) => _buildDialogOption(w, dialogContext)).toList();
                children.add(new Center(
                    child: new RaisedButton(
                        onPressed: () => _returnWord(context),
                        child: new Text('Cancel'),
                        color: Colors.deepOrange[300]
                    )));

                return new SimpleDialog(
                    title: new Text('Select a word definition'),
                    children: children
                );
            }
        ) : Future.value(words.firstWhere((_) => true, orElse: () => null));
    }

    static Widget _buildDialogOption(Word word, BuildContext context) {
        return new SimpleDialogOption(
            onPressed: () => _returnWord(context, word),
            child: new ListTile(
                title: new Text(word.partOfSpeech),
                subtitle: new Text(word.translations.join('; '))
            )
        );
    }

    static _returnWord(BuildContext context, [Word word]) => Navigator.pop(context, word);
}
