import 'package:flutter/material.dart';
import '../models/word.dart';
import './selector_dialog.dart';

class WordSelectorDialog extends SelectorDialog<Word> {
    final BuildContext _context;
    
    WordSelectorDialog(BuildContext context):
        _context = context,
        super();

    @override
    Future<Word> show(List<Word> words) {
        words = words ?? <Word>[];
        return words.length > 0 ? showDialog(
            context: _context,
            builder: (dialogContext) {
                final children = words.map((w) => _buildDialogOption(w)).toList();
                children.add(new Center(child: buildCancelBtn(_context)));

                return new SimpleDialog(
                    title: new Text('Select a word definition'),
                    children: children
                );
            }
        ) : Future.value(words.firstWhere((_) => true, orElse: () => null));
    } 

    Widget _buildDialogOption(Word word) => new SimpleDialogOption(
        onPressed: () => returnResult(_context, word),
        child: new ListTile(
            title: new Text(word.partOfSpeech),
            subtitle: new Text(word.translations.join('; '))
        )
    );
}
