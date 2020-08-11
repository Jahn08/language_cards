import 'package:flutter/material.dart';

class Router {
    static const String _NEW_CARD_ROUTE_NAME = 'newcard';

    static goToNewCard(BuildContext context) {
        Navigator.pushNamed(context, _NEW_CARD_ROUTE_NAME);
    }

    static bool isNewCardRoute(RouteSettings settings) => 
        settings.name == _NEW_CARD_ROUTE_NAME;

    static goHome(BuildContext context) {
        Navigator.pushNamed(context, '/');
    }
}
