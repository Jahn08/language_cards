import 'package:flutter/material.dart';
import './screens/main_screen.dart';
import './screens/new_card_screen.dart';
import './data/configuration.dart';
import './widgets/loader.dart';
import './router.dart';

class App extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return new MaterialApp(
            theme: new ThemeData.dark(),
            onGenerateRoute: (settings) {
                final route = Router.getRoute(settings);
                if (route is WordCardRoute)
                    return _buildNewCardRoute(route);

                return new MaterialPageRoute(
                    builder: (context) => new MainScreen()
                );
            }
        );
    }

    MaterialPageRoute _buildNewCardRoute(WordCardRoute route) {
        final params = route.params;
        return new MaterialPageRoute(
            builder: (context) => new FutureBuilder(
                future: Configuration.getParams(context),
                builder: (_, AsyncSnapshot<AppParams> snapshot) => snapshot.hasData ? 
                    new NewCardScreen(snapshot.data.dictionary.apiKey, params.storage, 
                        wordId: params.wordId) : 
                    new Loader()
            )
        );
    }
}
