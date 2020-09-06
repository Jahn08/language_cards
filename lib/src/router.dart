import 'package:flutter/material.dart';
import './data/base_storage.dart';
import './data/word_storage.dart';

class _StorageRouteArgs {
    final BaseStorage<StoredWord> storage;

    _StorageRouteArgs([BaseStorage<StoredWord> storage]): 
        storage = storage ?? WordStorage.instance;
}

class HomeRoute { 
    final _StorageRouteArgs params;

    HomeRoute.fromArguments(Object arguments): 
        params = arguments is _StorageRouteArgs ? arguments : new _StorageRouteArgs();
}

class _WordCardRouteArgs extends _StorageRouteArgs {
    final int wordId;

    _WordCardRouteArgs({ BaseStorage<StoredWord> storage, int wordId }): 
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

    static goToCard(BuildContext context, { BaseStorage<StoredWord> storage, int wordId }) {
        Navigator.pushNamed(context, _cardRouteName, 
            arguments: new _WordCardRouteArgs(storage: storage, wordId: wordId));
    }

    static dynamic getRoute(RouteSettings settings) {
        if (settings.name == _cardRouteName)
            return new WordCardRoute.fromArguments(settings.arguments);
        
        return new HomeRoute.fromArguments(settings.arguments);
    }

    static goHome(BuildContext context) {
        Navigator.pushNamed(context, '/');
    }
}
