import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' hide Router;
import '../router.dart';
import '../data/dictionary_provider.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../utilities/speaker.dart';
import '../widgets/card_editor.dart';
import '../widgets/bar_scaffold.dart';

class CardScreen extends StatelessWidget {
	
    final int wordId;
    
    final StoredPack pack;

    final DictionaryProvider provider;

    final ISpeaker defaultSpeaker;

    final BaseStorage<StoredWord> wordStorage;

    final BaseStorage<StoredPack> packStorage;
    
    CardScreen({ @required this.wordStorage, @required this.packStorage,
		@required this.provider, this.defaultSpeaker, this.pack, this.wordId });

    @override
    Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
		final title = this.wordId == null ? 
			locale.cardScreenHeadBarAddingCardTitle: locale.cardScreenHeadBarChangingCardTitle;

        return new BarScaffold(
			title: title,
            body: new CardEditor(wordStorage: wordStorage, packStorage: packStorage,
				provider: provider, defaultSpeaker: defaultSpeaker,
				pack: pack, wordId: wordId, 
				afterSave: (_, StoredPack pack, bool cardWasAdded) => 
					Router.goToCardList(context, pack: pack, cardWasAdded: cardWasAdded))
        );
    }
}
