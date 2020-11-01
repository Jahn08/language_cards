import 'package:flutter/material.dart';
import './blocs/settings_bloc.dart';
import './data/configuration.dart';
import './models/user_params.dart';
import './router.dart';
import './screens/pack_screen.dart';
import './screens/card_list_screen.dart';
import './screens/card_screen.dart';
import './screens/pack_list_screen.dart';
import './widgets/loader.dart';

class App extends StatelessWidget {

    @override
    Widget build(BuildContext context) => 
        new SettingsBlocProvider(child: new _ThemedApp());
}

class _ThemedAppState extends State<_ThemedApp> {

    SettingsBloc _bloc;

    @override
    Widget build(BuildContext context) {
        if (_bloc == null) {
            _bloc = SettingsBlocProvider.of(context);
            _bloc.addOnSaveListener(_updateState);
        }
        
        return new FutureLoader<UserParams>(_bloc.userParams, (params) {
            return new MaterialApp(
                theme: params.theme == AppTheme.dark ? new ThemeData.dark():
                    new ThemeData.light(),
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
                    else if (route is PackRoute) {
                        final params = route.params;
                        return new MaterialPageRoute(
                            settings: settings,
                            builder: (context) => new PackScreen(params.storage, 
                                packId: params.packId, packName: params.packName, 
                                refreshed: params.refreshed));
                    }
                        
                    return new MaterialPageRoute(
                        settings: settings,
                        builder: (context) => new PackListScreen((route as PackListRoute).params.storage));
                }
            );
        });
    }

    void _updateState(_) => setState(() { });

    MaterialPageRoute _buildCardRoute(WordCardRoute route, RouteSettings settings) {
        final params = route.params;
        return new MaterialPageRoute(
            settings: settings,
            builder: (context) => new FutureLoader(Configuration.getParams(context), 
                (data) {
                    return new CardScreen(data.dictionary.apiKey, 
                        wordStorage: params.storage, packStorage: params.packStorage,
                        wordId: params.wordId, pack: params.pack);
                })
            );
    }

    @override
    void dispose() {
        _bloc?.removeOnSaveListener(_updateState);
        
        super.dispose();
    }
}

class _ThemedApp extends StatefulWidget {

    @override
    State<StatefulWidget> createState() => new _ThemedAppState();
}
