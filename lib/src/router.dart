import 'package:flutter/material.dart';
import './data/word_storage.dart';

export './data/word_storage.dart' show IWordStorage;

class HomeRoute { }

class _WordCardRouteArgs {
    final int wordId;

    final IWordStorage storage;

    _WordCardRouteArgs({ IWordStorage storage, int wordId }): 
        wordId = wordId ?? 0,
        storage = storage ?? WordStorage.instance;
}

class WordCardRoute { 
    final _WordCardRouteArgs params;

    WordCardRoute.fromArguments(Object arguments): 
        params = arguments is _WordCardRouteArgs ? arguments : new _WordCardRouteArgs();
}

class Router {
    static const String _cardRouteName = 'card';

    static goToCard(BuildContext context, { IWordStorage storage, int wordId }) {
        Navigator.pushNamed(context, _cardRouteName, 
            arguments: new _WordCardRouteArgs(storage: storage, wordId: wordId));
    }

    static dynamic getRoute(RouteSettings settings) {
        if (settings.name == _cardRouteName)
            return new WordCardRoute.fromArguments(settings.arguments);
        
        return new HomeRoute();
    }

    static goHome(BuildContext context) {
        Navigator.pushNamed(context, '/');
    }
}
