import 'package:http/http.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/widgets.dart' hide Router;
import '../router.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../utilities/speaker.dart';
import '../widgets/card_editor.dart';
import '../widgets/bar_scaffold.dart';

class CardScreen extends StatelessWidget {
	
	final String apiKey;

    final int wordId;
    
    final StoredPack pack;

    final Client client;

    final ISpeaker defaultSpeaker;

    final BaseStorage<StoredWord> wordStorage;

    final BaseStorage<StoredPack> packStorage;
    
    CardScreen(this.apiKey, { @required this.wordStorage, @required this.packStorage, 
		this.client, this.defaultSpeaker, this.pack, this.wordId });

    @override
    Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
		final title = this.wordId == null ? 
			locale.cardScreenHeadBarAddingCardTitle: locale.cardScreenHeadBarChangingCardTitle;

        return new BarScaffold(
			title,
            body: new CardEditor(apiKey, wordStorage: wordStorage, packStorage: packStorage,
				client: client, defaultSpeaker: defaultSpeaker,
				pack: pack, wordId: wordId, 
				afterSave: (_, StoredPack pack, bool cardWasAdded) => 
					Router.goToCardList(context, pack: pack, cardWasAdded: cardWasAdded))
        );
    }
}
