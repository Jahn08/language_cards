import 'package:flutter/material.dart';

class HomeRoute { }

class WordCardRoute { 
    final int wordId;

    WordCardRoute.fromArguments(Object arguments): 
        wordId = arguments is int ? arguments : 0;
}

class Router {
    static const String _NEW_CARD_ROUTE_NAME = 'newcard';

    static goToNewCard(BuildContext context, { int wordId }) {
        Navigator.pushNamed(context, _NEW_CARD_ROUTE_NAME, arguments: wordId);
    }

    static dynamic getRoute(RouteSettings settings) {
        if (settings.name == _NEW_CARD_ROUTE_NAME)
            return new WordCardRoute.fromArguments(settings.arguments);
        
        return new HomeRoute();
    }

    static goHome(BuildContext context) {
        Navigator.pushNamed(context, '/');
    }
}
