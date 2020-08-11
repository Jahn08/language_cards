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
                if (Router.isNewCardRoute(settings))
                    return _buildNewCardRoute();

                return new MaterialPageRoute(
                    builder: (context) => new MainScreen()
                );
            }
        );
    }

    MaterialPageRoute _buildNewCardRoute() {
        return new MaterialPageRoute(
            builder: (context) => new FutureBuilder(
                future: Configuration.getParams(context),
                builder: (_, AsyncSnapshot<AppParams> snapshot) => snapshot.hasData ? 
                    new NewCardScreen(snapshot.data.dictionary.apiKey) : new Loader()
            )
        );
    }
}
