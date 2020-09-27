import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../data/pack_storage.dart';
import '../data/word_dictionary.dart';
import '../data/word_storage.dart';
import '../dialogs/word_selector_dialog.dart';
import '../dialogs/translation_selector_dialog.dart';
import '../models/word.dart';
import '../router.dart';
import '../widgets/english_phonetic_keyboard.dart';
import '../widgets/keyboarded_field.dart';
import '../widgets/loader.dart';
import '../widgets/styled_dropdown.dart';
import '../widgets/styled_text_field.dart';

class CardScreenState extends State<CardScreen> {
    final _key = new GlobalKey<FormState>();

    final WordDictionary _dictionary;

    final FocusNode _transcriptionFocusNode = new FocusNode();

    String _text;
    String _translation;
    String _transcription;
    String _partOfSpeech;

    bool _initialised = false;

    CardScreenState(String apiKey): _dictionary = new WordDictionary(apiKey);

    BaseStorage<StoredWord> get _storage => widget._storage;

    @override
    Widget build(BuildContext context) {
        return new Scaffold(
            appBar: new AppBar(
                title: new Text(_isNew ? 'Add Card' : "Change Card")
            ),
            body: new Form(
                key: _key,
                child: _buildFutureFormLayout(widget.wordId)
            )
        );
    }

    bool get _isNew => widget.wordId == 0;

    Widget _buildFutureFormLayout(int wordId) {
        final futureWord = _isNew || _initialised ? 
            Future.value(new StoredWord('')): _storage.find(widget.wordId);
        return new FutureBuilder(
            future: futureWord,
            builder: (context, AsyncSnapshot<StoredWord> snapshot) {
                if (!snapshot.hasData)
                    return new Loader();

                final foundWord = snapshot.data;
                if (foundWord != null && !foundWord.isNew && !_initialised) {
                    _initialised = true;

                    _text = foundWord.text;
                    _transcription = foundWord.transcription;
                    _partOfSpeech = foundWord.partOfSpeech;
                    _translation = foundWord.translation;
                }

                return _buildFormLayout();
            }
        );
    }

    Widget _buildFormLayout() {
        return new Column(
            children: <Widget>[
                new StyledTextField('Word Text', isRequired: true, 
                    onChanged: (value, submitted) async {
                        if (!submitted) {
                            setState(() => _text = value);
                            return;
                        }
                        
                        if (value == null || value.isEmpty)
                            return;

                        final article = await _dictionary.lookUp(value);
                        final chosenWord = await new WordSelectorDialog(context)
                            .show(article.words);

                        String translation;
                        if (chosenWord != null)
                            translation = await new TranslationSelectorDialog(context)
                                .show(chosenWord.translations);

                        setState(() {
                            if (chosenWord == null) {
                                _text = value;
                                return;
                            }

                            _text = chosenWord.text;
                            _partOfSpeech = chosenWord.partOfSpeech;
                            _transcription = chosenWord.transcription;
                            
                            if (translation != null)
                                _translation = translation;
                        });
                    }, initialValue: this._text),
                new KeyboardedField(new EnglishPhoneticKeyboard(this._transcription), 
                    _transcriptionFocusNode,
                    'Phonetic Notation', 
                    initialValue: this._transcription,
                    onChanged: (value) => setState(() => this._transcription = value)),
                new StyledDropdown(Word.PARTS_OF_SPEECH, label: 'Part of Speech',
                    initialValue: this._partOfSpeech,
                    onChanged: (value) => setState(() => this._partOfSpeech = value)),
                new StyledTextField('Translation', isRequired: true, 
                    initialValue: this._translation, 
                    onChanged: (value, _) => setState(() => this._translation = value)),
                new FlatButton.icon(
                    icon: new Icon(Icons.folder_open),
                    label: new Text('Card Pack: ${widget.pack?.name ?? 'None'}'),
                    onPressed: () => print('a dialog to choose a pack')
                ),
                new RaisedButton(
                    child: new Text('Save'),
                    onPressed: () {
                        final state = _key.currentState;
                        if (!state.validate())
                            return;

                        state.save();

                        final wordToSave = new StoredWord(this._text, 
                            id: widget.wordId,
                            packId: widget.pack?.id,
                            partOfSpeech: this._partOfSpeech, 
                            transcription: this._transcription,
                            translation: this._translation
                        );
                        final cardWasAdded = wordToSave.isNew;
                        _storage.save(wordToSave);

                        Router.goToCardList(context, pack: widget.pack, 
                            cardWasAdded: cardWasAdded);
                    }
                )
            ]
        );
    }

    @override
    dispose() {
        _dictionary.dispose();

        super.dispose();
    }
}

class CardScreen extends StatefulWidget {
    final String _apiKey;

    final int wordId;
    
    final StoredPack pack;

    final BaseStorage<StoredWord> _storage;
    
    CardScreen(String apiKey, BaseStorage<StoredWord> storage, { this.pack, this.wordId = 0 }): 
        _apiKey = apiKey,
        _storage = storage;

    @override
    CardScreenState createState() {
        return new CardScreenState(_apiKey);
    }
}
