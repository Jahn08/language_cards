import 'package:http/http.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter/widgets.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../data/pack_storage.dart';
import '../data/word_dictionary.dart';
import '../data/word_storage.dart';
import '../dialogs/pack_selector_dialog.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/translation_selector_dialog.dart';
import '../dialogs/word_selector_dialog.dart';
import '../models/part_of_speech.dart';
import '../models/presentable_enum.dart';
import '../models/word_study_stage.dart';
import '../utilities/speaker.dart';
import '../widgets/english_phonetic_keyboard.dart';
import '../widgets/keyboarded_field.dart';
import '../widgets/loader.dart';
import '../widgets/one_line_text.dart';
import '../widgets/styled_dropdown.dart';
import '../widgets/styled_text_field.dart';
import '../widgets/speaker_button.dart';

class CardEditorState extends State<CardEditor> {
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

	Map<String, PresentableEnum> _partOfSpeechDic;

    Future<StoredWord> futureWord;

    CardEditorState([Client client]): 
        this._client = client,
        super();

    @override
    void initState() {
        super.initState();

        if (widget.pack != null || _isNew)
            _setPack(widget.pack ?? StoredPack.none);

        futureWord = _isNew ? 
            Future.value(new StoredWord('')): _retrieveWord();
        
        _studyProgress = WordStudyStage.unknown;
    }

    void _setPack(StoredPack newPack) {
        _pack = newPack;

        _disposeDictionary();
        _dictionary = _isNonePack ? null: 
            new WordDictionary(widget._apiKey, from: _pack.from, to: _pack.to, 
                client: _client);

        if (_dictionary == null)
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => _warnWhenEmptyDictionary(context));
    }

    _disposeDictionary() => _dictionary?.dispose();

	bool get _isNonePack => _pack == null || _pack.isNone;

    Future<void> _warnWhenEmptyDictionary(BuildContext buildContext) 
		async {
			final locale = AppLocalizations.of(buildContext);
			await new ConfirmDialog.ok(
				title: locale.cardEditorChoosingPackDialogTitle, 
				content: locale.cardEditorChoosingPackDialogContent
			).show(buildContext);
		}

    @override
    Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
        return new Form(
			key: _key,
			child: widget.card == null ? 
				new FutureLoader(futureWord, (card) => _buildLayout(card, locale, context)): 
				_buildLayout(widget.card, locale, context)
		);
    }

    bool get _isNew => widget.wordId == null;

	Widget _buildLayout(StoredWord foundWord, AppLocalizations locale, BuildContext context) {
		if (foundWord != null && !foundWord.isNew && !_initialised) {
			_initialised = true;

			_text = foundWord.text;
			_transcription = foundWord.transcription;
			_partOfSpeech = foundWord.partOfSpeech?.present(locale);
			_translation = foundWord.translation;
			_studyProgress = foundWord.studyProgress;
		}

		return _buildFormLayout(locale, context);
	}

    Future<StoredWord> _retrieveWord() async {
        final word = await widget._wordStorage.find(widget.wordId);
    
        if (widget.pack == null) {
			final nonePack = StoredPack.none;

			_setPack(word.packId == nonePack.id ? nonePack: 
				await widget._packStorage.find(word.packId));
		}

        return word;
    }

    Widget _buildFormLayout(AppLocalizations locale, BuildContext context) {
		if (_partOfSpeechDic == null)
			_partOfSpeechDic = PresentableEnum.mapStringValues(PartOfSpeech.values, locale);

        return new Column(
            children: <Widget>[
				_isNonePack || _text == null || _text.isEmpty ? _buildCardTextField(locale): 
					new Row(children: [
						new Expanded(child:_buildCardTextField(locale)), 
							new SpeakerButton(_pack.from, (speaker) => speaker.speak(_text), 
							defaultSpeaker: widget._defaultSpeaker)
						]),
                new KeyboardedField(new EnglishPhoneticKeyboard(this._transcription), 
                    _transcriptionFocusNode,
					locale.cardEditorTranscriptionTextFieldLabel,
                    initialValue: this._transcription,
                    onChanged: (value) => setState(() => this._transcription = value)),
                new StyledDropdown(_partOfSpeechDic.keys, 
					label: locale.cardEditorPartOfSpeechDropdownLabel,
                    initialValue: this._partOfSpeech,
                    onChanged: (value) => setState(() => this._partOfSpeech = value)),
                new StyledTextField(locale.cardEditorTranslationTextFieldLabel, 
					isRequired: true, 
                    initialValue: this._translation, 
                    onChanged: (value, _) => setState(() => this._translation = value)),
				new TextButton.icon(
					icon: new Icon(Icons.folder_open),
					label: new Container(
						width: MediaQuery.of(context).size.width * 0.75,
						child: new OneLineText(locale.cardEditorChoosingPackButtonLabel(_pack.name))
					),
					onPressed: () async {
						if (_futurePacks == null) {
							_futurePacks = widget._packStorage.fetch();

							if (widget.hideNonePack ?? false)
								_futurePacks = _futurePacks.then(
									(ps) => ps.where((p) => !p.isNone).toList());
						}
						
						final chosenPack = await new PackSelectorDialog(context, _pack.id)
							.showAsync(_futurePacks);

						if (chosenPack != null && chosenPack.name != _pack.name)
							setState(() => _setPack(chosenPack));
					}
				),	
                if (this._studyProgress != WordStudyStage.unknown)
                    new TextButton.icon(
                        icon: new Icon(Icons.restore),
                        label: new Text(
							locale.cardEditorResettingStudyProgressButtonLabel(_studyProgress)
						),
                        onPressed: () =>  setState(
                            () => this._studyProgress = WordStudyStage.unknown)
                    ),
                new ElevatedButton(
                    child: new Text(locale.constsSavingItemButtonLabel),
                    onPressed: () async {
                        final state = _key.currentState;
                        if (!state.validate())
                            return;

                        state.save();

                        final wordToSave = new StoredWord(this._text, 
                            id: widget.wordId,
                            packId: _pack.id,
                            partOfSpeech: _partOfSpeechDic[this._partOfSpeech], 
                            transcription: this._transcription,
                            translation: this._translation,
                            studyProgress: this._studyProgress
                        );
                        final cardWasAdded = wordToSave.isNew || 
                            widget.pack?.id != _pack.id;
                        widget.afterSave?.call(
							(await widget._wordStorage.upsert([wordToSave])).first, _pack, cardWasAdded
						);
                    }
                )
            ]
        );
    }

	Widget _buildCardTextField(AppLocalizations locale) =>
		new StyledTextField(locale.cardEditorCardTextTextFieldLabel, 
			isRequired: true, 
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
					_partOfSpeech = chosenWord.partOfSpeech.present(locale);
					_transcription = chosenWord.transcription;
					_studyProgress = WordStudyStage.unknown;

					if (translation != null)
						_translation = translation;
				});
			}, initialValue: this._text);

    @override
    dispose() {
        _disposeDictionary();

        _client?.close();

        super.dispose();
    }
}

class CardEditor extends StatefulWidget {

    final String _apiKey;

    final StoredWord card;

    final int wordId;
    
    final StoredPack pack;

    final Client _client;

    final ISpeaker _defaultSpeaker;

    final BaseStorage<StoredWord> _wordStorage;

    final BaseStorage<StoredPack> _packStorage;
    
	final void Function(StoredWord card, StoredPack pack, bool cardWasAdded) afterSave;

	final bool hideNonePack;

    CardEditor(String apiKey, { @required BaseStorage<StoredWord> wordStorage, 
        @required BaseStorage<StoredPack> packStorage, @required this.afterSave,
		Client client, ISpeaker defaultSpeaker, int wordId, 
		this.pack, this.card, this.hideNonePack }): 
        _apiKey = apiKey,
        _client = client,
        _defaultSpeaker = defaultSpeaker,
        _packStorage = packStorage,
        _wordStorage = wordStorage,
		wordId = card?.id ?? wordId;

    @override
    CardEditorState createState() => new CardEditorState(_client);
}
