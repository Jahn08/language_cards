import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import '../data/word_dictionary.dart';
import '../router.dart';

class NewCardScreenState extends State<NewCardScreen> {
    final _key = new GlobalKey<FormState>();

    final WordDictionary _dictionary;

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
                _buildTextField('Enter the first word', isRequired: true, 
                    onChanged: (value) async {
                        final articles = await _dictionary.lookUp(value);

                        if (articles.words.length == 0)
                            return;

                        // TODO: Additional logic to render a list of possible alternatives
                        final firstWord = articles.words[0];
                        setState(() {
                            _word = firstWord.text;
                            _partOfSpeech = firstWord.partOfSpeech;
                            _transcription = firstWord.transcription;

                            if (firstWord.translations.length > 0)
                                _translation = firstWord.translations[0];
                        });
                    }, initialValue: _word),
                _buildTextField('Tap to alter its phonetic notation',
                    initialValue: this._transcription),
                _buildTextField('Tap to set up its part of speech',
                    initialValue: this._partOfSpeech),
                _buildTextField('Enter its translation', isRequired: true,
                    initialValue: this._translation),
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

    Widget _buildTextField(String hintText, 
        { bool isRequired, Function(String) onChanged, String initialValue }) {
        String value;
        
        isRequired = isRequired ?? false;

        return new TextFormField(
            keyboardType: TextInputType.text,
            decoration: new InputDecoration(
                hintText: hintText,
                contentPadding: EdgeInsets.only(left: 10, right: 10)
            ),
            autocorrect: true,
            onChanged: (val) => value = val,
            onEditingComplete: () => onChanged(value),
            validator: (String text) {
                if (isRequired && (text == null || text.isEmpty))
                    return 'The field is required';

                return null;
            },
            controller: new TextEditingController(text: initialValue)
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
