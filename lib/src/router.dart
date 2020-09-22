import 'package:flutter/material.dart';
import './models/stored_entity.dart';
import './data/base_storage.dart';
import './data/word_storage.dart';
import './data/pack_storage.dart';

class _StorageRouteArgs<T extends StoredEntity> {
    final BaseStorage<T> storage;

    _StorageRouteArgs(this.storage);
}

class _CardStorageRouteArgs extends _StorageRouteArgs<StoredWord> {
    _CardStorageRouteArgs([WordStorage storage]): super(storage ?? WordStorage.instance);
}

class _CardListRouteArgs extends _CardStorageRouteArgs {
    final StoredPack pack;

    final bool cardWasAdded;

    _CardListRouteArgs({ BaseStorage<StoredWord> storage, bool cardWasAdded, this.pack }):
        cardWasAdded = cardWasAdded ?? false, 
        super(storage);
}

class CardListRoute { 
    final _CardListRouteArgs params;

    CardListRoute.fromArguments(Object arguments): 
        params = arguments is _CardListRouteArgs ? arguments : new _CardListRouteArgs();
}

class _PackStorageRouteArgs extends _StorageRouteArgs<StoredPack> {
    _PackStorageRouteArgs([WordStorage storage]): super(storage ?? PackStorage.instance);
}

class PackListRoute { 
    final _PackStorageRouteArgs params;

    PackListRoute.fromArguments(Object arguments): 
        params = arguments is _PackStorageRouteArgs ? arguments : new _PackStorageRouteArgs();
}

class _WordCardRouteArgs extends _CardStorageRouteArgs {
    final int wordId;

    final StoredPack pack;

    _WordCardRouteArgs({ BaseStorage<StoredWord> storage, int wordId, this.pack }): 
        wordId = wordId ?? 0,
        super(storage);
}

class WordCardRoute { 
    final _WordCardRouteArgs params;

    WordCardRoute.fromArguments(Object arguments): 
        params = arguments is _WordCardRouteArgs ? arguments : new _WordCardRouteArgs();
}

class Router {
    static const String _cardRouteName = 'card';

    static const String _cardListRouteName = 'cardList';

    static const String _packListRouteName = 'packList';

    static String get initialRouteName => _packListRouteName;

    static goToCard(BuildContext context, 
        { BaseStorage<StoredWord> storage, int wordId, StoredPack pack }) {
        Navigator.pushNamed(context, _cardRouteName, 
            arguments: new _WordCardRouteArgs(storage: storage, wordId: wordId, pack: pack));
    }

    static goToCardList(BuildContext context, 
        { BaseStorage<StoredWord> storage, StoredPack pack, bool cardWasAdded }) {
        Navigator.pushNamed(context, _cardListRouteName, 
            arguments: new _CardListRouteArgs(storage: storage, pack: pack,
                cardWasAdded: cardWasAdded));
    }

    static dynamic getRoute(RouteSettings settings) {
        switch (settings.name) {
            case _cardRouteName:
                return new WordCardRoute.fromArguments(settings.arguments);
            case _cardListRouteName:
                return new CardListRoute.fromArguments(settings.arguments);
            default:        
                return new PackListRoute.fromArguments(settings.arguments);
        }
    }

    static goHome(BuildContext context) => Navigator.pushNamed(context, initialRouteName);

    static goToPackList(BuildContext context) => Navigator.pushNamed(context, _packListRouteName);

    static goBackToPackList(BuildContext context) => 
        Navigator.popUntil(context, ModalRoute.withName(_packListRouteName));
}
