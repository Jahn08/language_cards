import 'package:flutter/material.dart';
import './screens/card_list_screen.dart';
import './screens/card_screen.dart';
import './screens/pack_list_screen.dart';
import './data/configuration.dart';
import './widgets/loader.dart';
import './router.dart';

class App extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return new MaterialApp(
            theme: new ThemeData.dark(),
            initialRoute: Router.initialRouteName,
            onGenerateRoute: (settings) {
                final route = Router.getRoute(settings);
                if (route is WordCardRoute)
                    return _buildCardRoute(route, settings);
                else if (route is CardListRoute) {
                    final params = route.params;
                    return new MaterialPageRoute(
                        settings: settings,
                        builder: (context) => new CardListScreen(params.storage, 
                            pack: params.pack, cardWasAdded: params.cardWasAdded));
                }
                    
                return new MaterialPageRoute(
                    settings: settings,
                    builder: (context) => new PackListScreen((route as PackListRoute).params.storage));
            }
        );
    }

    MaterialPageRoute _buildCardRoute(WordCardRoute route, RouteSettings settings) {
        final params = route.params;
        return new MaterialPageRoute(
            settings: settings,
            builder: (context) => new FutureBuilder(
                future: Configuration.getParams(context),
                builder: (_, AsyncSnapshot<AppParams> snapshot) => snapshot.hasData ? 
                    new CardScreen(snapshot.data.dictionary.apiKey, params.storage, 
                        wordId: params.wordId, pack: params.pack) : 
                    new Loader()
            )
        );
    }
}
