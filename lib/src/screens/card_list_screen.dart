import 'package:flutter/material.dart';
import '../data/base_storage.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import './list_screen.dart';
import '../router.dart';

class _CardListScreenState extends ListScreenState<StoredWord, CardListScreen> {
    bool _cardsWereRemoved = false;

    @override
    Widget getItemSubtitle(StoredWord item) => super.buildOneLineText(item.translation);
    
    @override
    Widget getItemTitle(StoredWord item) => super.buildOneLineText(item.text);
    
    @override
    Widget getItemTrailing(StoredWord item) => super.buildOneLineText(item.partOfSpeech);

    @override
    void onLeaving(BuildContext buildContext, [StoredWord item]) {
        super.onLeaving(buildContext, item);
        
        Router.goToCard(buildContext, wordId: item?.id, pack: widget.pack);
    }

    @override
    Future<List<StoredWord>> fetchNextItems(int skipCount, int takeCount) =>
        widget.storage.fetch(skipCount: skipCount, takeCount: takeCount, 
            parentId: widget.pack?.id);
  
    @override
    void removeItems(List<int> ids) {
        widget.storage.remove(ids);

        _cardsWereRemoved = true;
    }

    @override
    String get title => widget.pack?.name ?? 'Word Cards';

    @override
    bool get canGoBack => true;

    @override
    void onGoingBack(BuildContext context) => _cardsWereRemoved || widget.cardWasAdded ? 
        Router.goToPackList(context): Router.goBackToPackList(context);
}

class CardListScreen extends StatefulWidget {
    final BaseStorage<StoredWord> storage;

    final StoredPack pack;

    final bool cardWasAdded;

    CardListScreen(this.storage, { this.pack, bool cardWasAdded }):
        cardWasAdded = cardWasAdded ?? false;

    @override
    _CardListScreenState createState() => new _CardListScreenState();
}
