import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

class NewCardScreenState extends State<NewCardScreen> {
    final _key = new GlobalKey<FormState>();

    final WordDictionary _dictionary;

    final FocusNode _transcriptionFocusNode = new FocusNode();

    String _text;
    String _translation;
    String _transcription;
    String _partOfSpeech;

    bool _initialised = false;

    NewCardScreenState(String apiKey): _dictionary = new WordDictionary(apiKey);

    @override
    Widget build(BuildContext context) {
        return new Scaffold(
            appBar: new AppBar(
                title: new Text('New Card')
            ),
            body: new Form(
                key: _key,
                child: widget.wordId > 0 && !_initialised ? _buildFutureFormLayout(widget.wordId) : 
                    _buildFormLayout()
            )
        );
    }

    Widget _buildFutureFormLayout(int wordId) {
        return new FutureBuilder(
            future: WordStorage.instance.find(wordId),
            builder: (context, AsyncSnapshot<StoredWord> snapshot) {
                if (!snapshot.hasData)
                    return new Loader();

                final foundWord = snapshot.data;
                if (foundWord != null) {
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
        _initialised = true;
        return new Column(
            children: <Widget>[
                new StyledTextField('Enter the first word', isRequired: true, 
                    onChanged: (value) async {
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
                    'Tap to alter its phonetic notation', 
                    _transcriptionFocusNode,
                    initialValue: this._transcription,
                    onChanged: (value) => setState(() => this._transcription = value)),
                new StyledDropdown(Word.PARTS_OF_SPEECH, 'Tap to set up its part of speech',
                    initialValue: this._partOfSpeech,
                    onChanged: (value) => setState(() => this._partOfSpeech = value)),
                new StyledTextField('Enter its translation', isRequired: true, 
                    initialValue: this._translation, 
                    onChanged: (value) => setState(() => this._translation = value)),
                new RaisedButton(
                    child: new Text('Save'),
                    onPressed: () {
                        final state = _key.currentState;
                        if (state.validate()) {
                            state.save();

                            WordStorage.instance.save(new StoredWord(this._text, 
                                id: widget.wordId,
                                partOfSpeech: this._partOfSpeech, 
                                transcription: this._transcription,
                                translation: this._translation
                            ));
                            Router.goHome(context);
                        }
                    }
                )
            ]
        );
    }
}

class NewCardScreen extends StatefulWidget {
    final String _apiKey;

    final int wordId;
    
    NewCardScreen(String apiKey, { this.wordId }): 
        _apiKey = apiKey;

    @override
    NewCardScreenState createState() {
        return new NewCardScreenState(_apiKey);
    }
}
