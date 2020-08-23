import 'package:flutter/material.dart';
import '../models/word.dart';

class WordSelectorDialog {

    static Future<Word> show(List<Word> words, BuildContext context) {
        return words.length > 1 ? showDialog(
            context: context,
            builder: (dialogContext) {
                return new SimpleDialog(
                    title: new Text('Select a word definition'),
                    children: words.map((w) => _buildDialogOption(w, dialogContext)).toList()
                );
            }
        ) : Future.value(words.first);
    }

    static Widget _buildDialogOption(Word word, BuildContext context) {
        return new SimpleDialogOption(
            onPressed: () => Navigator.pop(context, word),
            child: new ListTile(
                title: new Text(word.partOfSpeech),
                subtitle: new Text(word.translations.join('; '))
            )
        );
    }
}
