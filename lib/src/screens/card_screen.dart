import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import '../data/pack_storage.dart';
import '../data/word_dictionary.dart';
import '../data/word_storage.dart';
import '../dialogs/pack_selector_dialog.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/translation_selector_dialog.dart';
import '../dialogs/word_selector_dialog.dart';
import '../models/word.dart';
import '../router.dart';
import '../widgets/english_phonetic_keyboard.dart';
import '../widgets/keyboarded_field.dart';
import '../widgets/loader.dart';
import '../widgets/settings_scaffold.dart';
import '../widgets/styled_dropdown.dart';
import '../widgets/styled_text_field.dart';

class CardScreenState extends State<CardScreen> {
    final _key = new GlobalKey<FormState>();

    final FocusNode _transcriptionFocusNode = new FocusNode();

    final Client _client;

    Future<List<StoredPack>> _futurePacks;
    StoredPack _pack;

    WordDictionary _dictionary;

    String _text;
    String _translation;
    String _transcription;
    String _partOfSpeech;
    
    int _studyProgress;

    bool _initialised = false;

    CardScreenState([Client client]): 
        this._client = client,
        super();

    @override
    void initState() {
        super.initState();

        _setPack(widget.pack ?? StoredPack.none);
        _studyProgress = WordStudyStage.unknown;
    }

    _setPack(StoredPack newPack) {
        _pack = newPack;

        _disposeDictionary();
        _dictionary = _pack == null || _pack.isNone ? null: 
            new WordDictionary(widget._apiKey, from: _pack.from, to: _pack.to, 
                client: _client);

        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _warnWhenEmptyDictionary(context));
    }

    _disposeDictionary() => _dictionary?.dispose();

    Future<void> _warnWhenEmptyDictionary(BuildContext buildContext) async {
        if (_dictionary != null)
            return;

        await new ConfirmDialog<bool>(
            title: 'Choose Pack', 
            content: 'You should choose a pack to make automatic translation' + 
                ' available for the word',
            actions: { true: 'OK' }
        ).show(buildContext);
    }

    @override
    Widget build(BuildContext context) {
        return new SettingsScaffold(
            _isNew ? 'Add Card' : "Change Card",
            body: new Form(
                key: _key,
                child: _buildFutureFormLayout()
            )
        );
    }

    bool get _isNew => widget.wordId == 0;

    Widget _buildFutureFormLayout() {
        final futureWord = _isNew || _initialised ? 
            Future.value(new StoredWord('')): widget._wordStorage.find(widget.wordId);
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
                    _studyProgress = foundWord.studyProgress;
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
                        if (!submitted || _dictionary == null) {
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
                            _studyProgress = WordStudyStage.unknown;

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
                    label: new Text('Card Pack: ${_pack.name}'),
                    onPressed: () async {
                        if (_futurePacks == null)
                            _futurePacks = widget._packStorage.fetch();
                        
                        final chosenPack = await new PackSelectorDialog(context, _pack.id)
                            .showAsync(_futurePacks);

                        if (chosenPack != null && chosenPack.name != _pack.name)
                            setState(() => _setPack(chosenPack));
                    }
                ),
                if (this._studyProgress != WordStudyStage.unknown)
                    new FlatButton.icon(
                        icon: new Icon(Icons.restore),
                        label: new Text('Reset ${this._studyProgress}% Progress'),
                        onPressed: () =>  setState(
                            () => this._studyProgress = WordStudyStage.unknown)
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
                            packId: _pack.id,
                            partOfSpeech: this._partOfSpeech, 
                            transcription: this._transcription,
                            translation: this._translation,
                            studyProgress: this._studyProgress
                        );
                        final cardWasAdded = wordToSave.isNew || 
                            widget.pack?.id != _pack.id;
                        widget._wordStorage.upsert(wordToSave);

                        Router.goToCardList(context, pack: _pack, 
                            cardWasAdded: cardWasAdded);
                    }
                )
            ]
        );
    }

    @override
    dispose() {
        _disposeDictionary();

        _client?.close();

        super.dispose();
    }
}

class CardScreen extends StatefulWidget {
    final String _apiKey;

    final int wordId;
    
    final StoredPack pack;

    final Client _client;

    final BaseStorage<StoredWord> _wordStorage;

    final BaseStorage<StoredPack> _packStorage;
    
    CardScreen(String apiKey, { @required BaseStorage<StoredWord> wordStorage, 
        @required BaseStorage<StoredPack> packStorage, Client client,
        this.pack, this.wordId = 0 }): 
        _apiKey = apiKey,
        _client = client,
        _packStorage = packStorage,
        _wordStorage = wordStorage;

    @override
    CardScreenState createState() => new CardScreenState(_client);
}
