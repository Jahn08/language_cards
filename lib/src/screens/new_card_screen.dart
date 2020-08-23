import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../data/word_dictionary.dart';
import '../router.dart';
import '../widgets/styled_text_field.dart';
import '../widgets/styled_dropdown.dart';
import '../widgets/keyboarded_field.dart';
import '../widgets/english_phonetic_keyboard.dart';
import '../widgets/word_selector_dialog.dart';
import '../models/word.dart';

class NewCardScreenState extends State<NewCardScreen> {
    final _key = new GlobalKey<FormState>();

    final WordDictionary _dictionary;

    final FocusNode _transcriptionFocusNode = new FocusNode();

    String _word;
    String _translation;
    String _transcription;
    String _partOfSpeech;

    NewCardScreenState(String apiKey): _dictionary = new WordDictionary(apiKey);

    @override
    Widget build(BuildContext context) {
        return new Scaffold(
            appBar: new AppBar(
                title: new Text('New Card')
            ),
            body: new Form(
                key: _key,
                child: _buildFormLayout()
            )
        );
    }

    Widget _buildFormLayout() {
        return new Column(
            children: <Widget>[
                new StyledTextField('Enter the first word', isRequired: true, 
                    onChanged: (value) async {
                        if (value == null || value.isEmpty)
                            return;

                        final article = await _dictionary.lookUp(value);
                        final words = article.words.length == 0 ? [new Word(value)]: article.words;
                        final chosenWord = await WordSelectorDialog.show(words, context);

                        setState(() {
                            if (chosenWord == null) {
                                _word = value;
                                return;
                            }

                            _word = chosenWord.text;
                            _partOfSpeech = chosenWord.partOfSpeech;
                            _transcription = chosenWord.transcription;

                            if (chosenWord.translations.length > 0)
                                _translation = chosenWord.translations[0];
                        });
                    }, initialValue: this._word),
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

                            // TODO: Perform some actons here through a bloc

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
    
    NewCardScreen(String apiKey): _apiKey = apiKey;

    @override
    NewCardScreenState createState() {
        return new NewCardScreenState(_apiKey);
    }
}
