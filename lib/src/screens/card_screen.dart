import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' hide Router;
import '../data/dictionary_provider.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../models/language.dart';
import '../router.dart';
import '../utilities/speaker.dart';
import '../widgets/card_editor.dart';
import '../widgets/bar_scaffold.dart';

class CardScreen extends StatelessWidget {
  final int? wordId;

  final StoredPack? pack;

  final DictionaryProvider provider;

  final ISpeaker? defaultSpeaker;

  final WordStorage wordStorage;

  final PackStorage packStorage;

  final LanguagePair? languagePair;

  const CardScreen(
      {required this.wordStorage,
      required this.packStorage,
      required this.provider,
      this.defaultSpeaker,
      this.pack,
      this.wordId,
      this.languagePair});

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final title = wordId == null
        ? locale!.cardScreenHeadBarAddingCardTitle
        : locale!.cardScreenHeadBarChangingCardTitle;

    final cardEditor = new CardEditor(
        wordStorage: wordStorage,
        packStorage: packStorage,
        provider: provider,
        defaultSpeaker: defaultSpeaker,
        pack: pack,
        wordId: wordId,
        languagePair: languagePair,
        afterSave: (_, __, {bool refresh = false}) =>
            Router.goBackToCardList(context, pack: pack, refresh: refresh));

    return new BarScaffold(
        title: title,
        onNavGoingBack: () async {
          if (await cardEditor.shouldDiscardChanges() && context.mounted)
            Router.goBackToCardList(context, pack: pack);
        },
        body: cardEditor);
  }
}
