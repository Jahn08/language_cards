import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'popup_text_field.dart';
import './keyboarded_field.dart';
import './loader.dart';
import './no_translation_snack_bar.dart';
import './one_line_text.dart';
import './styled_dropdown.dart';
import './styled_text_field.dart';
import './speaker_button.dart';
import '../data/dictionary_provider.dart';
import '../data/pack_storage.dart';
import '../data/word_dictionary.dart';
import '../data/word_storage.dart';
import '../dialogs/pack_selector_dialog.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/merge_selector_dialog.dart';
import '../dialogs/translation_selector_dialog.dart';
import '../dialogs/word_selector_dialog.dart';
import '../models/part_of_speech.dart';
import '../models/presentable_enum.dart';
import '../models/word_study_stage.dart';
import '../utilities/speaker.dart';

class CardEditorState extends State<CardEditor> {
  final _key = new GlobalKey<FormState>();

  final FocusNode _transcriptionFocusNode = new FocusNode();

  WordDictionary _dictionary;

  Future<List<StoredPack>> _futurePacks;

  final _isStateDirtyNotifier = new ValueNotifier(false);

  final _packNotifier = new ValueNotifier<StoredPack>(null);

  final _textNotifier = new ValueNotifier<String>(null);
  final _translationNotifier = new ValueNotifier<String>(null);
  final _transcriptionNotifier = new ValueNotifier<String>(null);
  final _partOfSpeechNotifier = new ValueNotifier<String>(null);

  final _studyProgressNotifier = new ValueNotifier<int>(WordStudyStage.unknown);

  Map<String, PartOfSpeech> _partOfSpeechDic;

  Future<StoredWord> _futureCard;
  StoredWord _foundCard;

  Set<String> _foundLemmas = <String>{};
  int _prevSearchedLemmaLength = 0;

  @override
  void initState() {
    super.initState();

    if (widget.pack != null || _isNew) _setPack(widget.pack ?? StoredPack.none);

    _futureCard = _isNew ? Future.value(new StoredWord('')) : _retrieveWord();

    _getFuturePacks();
  }

  Future<List<StoredPack>> _getFuturePacks() async {
    if (_futurePacks == null) {
      _futurePacks = widget._packStorage.fetch();

      if (widget.hideNonePack ?? false)
        _futurePacks =
            _futurePacks.then((ps) => ps.where((p) => !p.isNone).toList());
    }

    return _futurePacks;
  }

  void _setPack(StoredPack newPack) {
    _packNotifier.value = newPack;
    _setStateDirtiness();

    _disposeDictionary();
    _dictionary = _isNonePack
        ? null
        : new WordDictionary(widget._provider,
            from: newPack.from, to: newPack.to);

    if (_dictionary == null)
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _warnWhenEmptyDictionary(context));
    else
      _dictionary.isTranslationPossible().then((resp) {
        if (!resp) NoTranslationSnackBar.show(context);
      });
  }

  Future<StoredWord> _retrieveWord() async {
    final word = await widget._wordStorage.find(widget.wordId);

    if (widget.pack == null) {
      final nonePack = StoredPack.none;

      _setPack(word.packId == nonePack.id
          ? nonePack
          : await widget._packStorage.find(word.packId));
    }

    return word;
  }

  void _disposeDictionary() => _dictionary?.dispose();

  bool get _isNonePack =>
      _packNotifier.value == null || _packNotifier.value.isNone;

  Future<void> _warnWhenEmptyDictionary(BuildContext buildContext) async {
    final locale = AppLocalizations.of(buildContext);
    await new ConfirmDialog.ok(
            title: locale.cardEditorChoosingPackDialogTitle,
            content: locale.cardEditorChoosingPackDialogContent)
        .show(buildContext);
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    return new Form(
        key: _key,
        child: new FutureLoader(
            widget.card == null ? _futureCard : Future.value(widget.card),
            (StoredWord card) {
          if (card != null && !card.isNew && _foundCard == null) {
            _foundCard = card;

            _textNotifier.value = card.text;
            _transcriptionNotifier.value = card.transcription;
            _partOfSpeechNotifier.value = card.partOfSpeech?.present(locale);
            _translationNotifier.value = card.translation;
            _studyProgressNotifier.value = card.studyProgress;
          }

          _partOfSpeechDic ??=
              PresentableEnum.mapStringValues(PartOfSpeech.values, locale);
          return new Column(children: <Widget>[
            new ValueListenableBuilder(
                valueListenable: _textNotifier,
                builder: (_, String text, __) {
                  final textField = new PopupTextField(
                      locale.cardEditorCardTextTextFieldLabel,
                      isRequired: true,
                      popupItemsBuilder: _buildPopupValues,
                      onChanged: (value, submitted) async {
                    await _updateCardValues(value, submitted);
                    _setStateDirtiness();
                  }, initialValue: text);

                  return new ValueListenableBuilder(
                      valueListenable: _packNotifier,
                      builder: (_, StoredPack pack, __) => _isNonePack ||
                              text == null ||
                              text.isEmpty
                          ? textField
                          : new Row(children: [
                              new Expanded(child: textField),
                              new SpeakerButton(
                                  pack.from, (speaker) => speaker.speak(text),
                                  defaultSpeaker: widget._defaultSpeaker)
                            ]));
                }),
            new AnimatedBuilder(
                animation:
                    Listenable.merge([_transcriptionNotifier, _packNotifier]),
                builder: (_, __) => new KeyboardedField(
                        _packNotifier.value?.from,
                        _transcriptionFocusNode,
                        locale.cardEditorTranscriptionTextFieldLabel,
                        initialValue: _transcriptionNotifier.value,
                        onChanged: (value) {
                      _transcriptionNotifier.value = value;
                      _setStateDirtiness();
                    })),
            new ValueListenableBuilder(
              valueListenable: _partOfSpeechNotifier,
              builder: (_, String partOfSpeech, __) => new StyledDropdown(
                  _partOfSpeechDic.keys,
                  label: locale.cardEditorPartOfSpeechDropdownLabel,
                  initialValue: partOfSpeech, onChanged: (value) {
                _partOfSpeechNotifier.value = value;
                _setStateDirtiness();
              }),
            ),
            new ValueListenableBuilder(
              valueListenable: _translationNotifier,
              builder: (_, String translation, __) => new StyledTextField(
                  locale.cardEditorTranslationTextFieldLabel,
                  isRequired: true,
                  initialValue: translation, onChanged: (value, _) {
                _translationNotifier.value = value;
                _setStateDirtiness();
              }),
            ),
            new _BtnLink(new ValueListenableBuilder(
                valueListenable: _packNotifier,
                child: const Icon(Icons.folder_open),
                builder: (_, StoredPack pack, icon) => new TextButton.icon(
                    icon: icon,
                    label: new SizedBox(
                        width: MediaQuery.of(context).size.width * 0.6,
                        child: new OneLineText(
                            locale.cardEditorChoosingPackButtonLabel(
                                pack.getLocalisedName(context)))),
                    onPressed: () async {
                      final pack = _packNotifier.value;
                      final chosenPack =
                          await new PackSelectorDialog(context, pack.id)
                              .showAsync(_getFuturePacks());

                      if (chosenPack != null && chosenPack.name != pack.name)
                        _setPack(chosenPack);
                    }))),
            new ValueListenableBuilder(
                valueListenable: _studyProgressNotifier,
                builder: (_, int studyProgress, __) => studyProgress ==
                        WordStudyStage.unknown
                    ? const SizedBox()
                    : new _BtnLink(new TextButton.icon(
                        icon: const Icon(Icons.restore),
                        label: new Text(
                            locale.cardEditorResettingStudyProgressButtonLabel(
                                studyProgress)),
                        onPressed: () {
                          _studyProgressNotifier.value = WordStudyStage.unknown;
                          _setStateDirtiness();
                        }))),
            new ValueListenableBuilder(
                valueListenable: _isStateDirtyNotifier,
                builder: (_, bool isStateDirty, __) => new ElevatedButton(
                    child: new Text(locale.constsSavingItemButtonLabel),
                    onPressed: isStateDirty ? () => onSave(locale) : null))
          ]);
        }));
  }

  Future<void> onSave(AppLocalizations locale) async {
    final state = _key.currentState;
    if (!state.validate()) return;

    state.save();

    StoredPack pack = _packNotifier.value;
    final wordToSave = await _mergeIfDuplicated(
        new StoredWord(_textNotifier.value,
            id: widget.wordId,
            packId: pack.id,
            partOfSpeech: _partOfSpeechDic[_partOfSpeechNotifier.value],
            transcription: _transcriptionNotifier.value,
            translation: _translationNotifier.value,
            studyProgress: _studyProgressNotifier.value),
        pack,
        locale);

    if (wordToSave == null) return;

    if (pack.id != wordToSave.packId)
      pack = (await _getFuturePacks())
          .firstWhere((p) => p.id == wordToSave.packId);

    final cardWasAdded = wordToSave.isNew || widget.pack?.id != pack.id;
    widget.afterSave?.call(
        (await widget._wordStorage.upsert([wordToSave])).first,
        pack,
        cardWasAdded);
  }

  bool get _isNew => widget.wordId == null;

  Future<Iterable<String>> _buildPopupValues(String value) async {
    if (_dictionary == null || (value ?? '').trim().isEmpty) return [];

    final tilesNumber = _foundLemmas.length;
    if (tilesNumber == 1 && _foundLemmas.contains(value)) return [];

    if (tilesNumber > 0 &&
        tilesNumber < WordDictionary.searcheableLemmaMaxNumber &&
        _prevSearchedLemmaLength > 0 &&
        _prevSearchedLemmaLength <= value.length) {
      final lemmas = _foundLemmas.where((el) => el.contains(value)).toList();
      return lemmas.length == 1 && lemmas.contains(value) ? [] : lemmas;
    }

    _prevSearchedLemmaLength = value.length;
    return _foundLemmas = await _dictionary.searchForLemmas(value);
  }

  Future<void> _updateCardValues(String value, bool submitted) async {
    if (!submitted || _dictionary == null) {
      _textNotifier.value = value;
      return;
    }

    if (value == null || value.isEmpty) return;

    final article = await _dictionary.lookUp(value);

    if (!mounted) return;

    final chosenWord =
        await new WordSelectorDialog(context).show(article?.words);

    if (chosenWord == null) {
      _textNotifier.value = value;
      return;
    }

    if (!mounted) return;

    String translation;
    if (chosenWord != null)
      translation = await new TranslationSelectorDialog(context)
          .show(chosenWord.translations);

    if (!mounted) return;

    _textNotifier.value = chosenWord.text;
    _partOfSpeechNotifier.value =
        chosenWord.partOfSpeech.present(AppLocalizations.of(context));
    _transcriptionNotifier.value = chosenWord.transcription;
    _studyProgressNotifier.value = WordStudyStage.unknown;

    if (translation != null) _translationNotifier.value = translation;
  }

  void _setStateDirtiness() => _isStateDirtyNotifier.value = _isNew ||
      (_foundCard != null &&
          (_foundCard.text != _textNotifier.value ||
              _foundCard.translation != _translationNotifier.value ||
              _foundCard.transcription != _transcriptionNotifier.value ||
              _foundCard.partOfSpeech !=
                  _partOfSpeechDic[_partOfSpeechNotifier.value] ||
              _foundCard.studyProgress != _studyProgressNotifier.value ||
              _foundCard.packId != _packNotifier.value?.id));

  Future<StoredWord> _mergeIfDuplicated(
      StoredWord word, StoredPack pack, AppLocalizations locale) async {
    final supposedDuplicates = await widget._wordStorage
        .findDuplicates(text: word.text, pos: word.partOfSpeech, id: word.id);

    if (supposedDuplicates.isEmpty) return word;

    final allPacks = await _getFuturePacks();
    final sameTranslationPacks = {
      for (final p
          in allPacks.where((p) => p.from == pack.from && p.to == pack.to))
        p.id: p
    };
    final duplicatedWords = supposedDuplicates
        .where((w) =>
            w.packId == word.packId || sameTranslationPacks[w.packId] != null)
        .toList();
    if (!mounted || duplicatedWords.isEmpty) return word;

    final duplicatesNumber = duplicatedWords.length;
    // ignore: use_build_context_synchronously
    final shouldMerge = await new ConfirmDialog(
            title: locale.cardEditorDuplicatedCardDialogTitle,
            confirmationLabel:
                locale.cardEditorDuplicatedCardDialogConfirmationButtonLabel,
            cancellationLabel:
                locale.cardEditorDuplicatedCardDialogCancellationButtonLabel,
            content: duplicatesNumber > 1
                ? locale.cardEditorDuplicatedCardDialogSeveralItemsContent(
                    duplicatesNumber)
                : locale.cardEditorDuplicatedCardDialogSingleItemContent)
        .show(context);

    if (shouldMerge) {
      StoredWord wordToMergeWith;
      if (duplicatesNumber > 1 && mounted) {
        final packNamesById = {
          for (final p in sameTranslationPacks.entries) p.key: p.value.name
        };
        // ignore: use_build_context_synchronously
        wordToMergeWith = await new MergeSelectorDialog(context, packNamesById)
            .show(duplicatedWords);
      } else
        wordToMergeWith = duplicatedWords.first;

      return wordToMergeWith == null
          ? null
          : new StoredWord(wordToMergeWith.text,
              id: wordToMergeWith.id,
              packId: wordToMergeWith.packId,
              partOfSpeech: wordToMergeWith.partOfSpeech,
              transcription: wordToMergeWith.transcription,
              translation:
                  wordToMergeWith.translation + '; ' + word.translation,
              studyProgress: wordToMergeWith.studyProgress);
    }

    return word;
  }

  @override
  void dispose() {
    _disposeDictionary();

    _textNotifier.dispose();
    _translationNotifier.dispose();
    _transcriptionNotifier.dispose();
    _partOfSpeechNotifier.dispose();

    _studyProgressNotifier.dispose();

    _packNotifier.dispose();

    _isStateDirtyNotifier.dispose();

    super.dispose();
  }
}

class _BtnLink extends StatelessWidget {
  final Widget child;

  const _BtnLink(this.child);

  @override
  Widget build(BuildContext context) =>
      new Container(alignment: Alignment.centerLeft, child: child);
}

class CardEditor extends StatefulWidget {
  final StoredWord card;

  final int wordId;

  final StoredPack pack;

  final DictionaryProvider _provider;

  final ISpeaker _defaultSpeaker;

  final WordStorage _wordStorage;

  final BaseStorage<StoredPack> _packStorage;

  final void Function(StoredWord card, StoredPack pack, bool refresh) afterSave;

  final bool hideNonePack;

  CardEditor(
      {@required WordStorage wordStorage,
      @required BaseStorage<StoredPack> packStorage,
      @required this.afterSave,
      @required DictionaryProvider provider,
      ISpeaker defaultSpeaker,
      int wordId,
      this.pack,
      this.card,
      this.hideNonePack})
      : _provider = provider,
        _defaultSpeaker = defaultSpeaker,
        _packStorage = packStorage,
        _wordStorage = wordStorage,
        wordId = card?.id ?? wordId;

  @override
  CardEditorState createState() => new CardEditorState();
}
