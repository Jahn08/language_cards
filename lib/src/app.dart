import 'package:flutter/material.dart' hide Router;
import './blocs/settings_bloc.dart';
import './data/configuration.dart';
import './models/user_params.dart';
import './router.dart';
import './screens/card_list_screen.dart';
import './screens/card_screen.dart';
import './screens/main_screen.dart';
import './screens/pack_list_screen.dart';
import './screens/pack_screen.dart';
import './screens/study_screen.dart';
import './screens/study_preparer_screen.dart';
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
                onGenerateRoute: (settings) => _buildPageRoute(settings, (context, route) {
                    if (route == null)
                        return new MainScreen();
                    else if (route is WordCardRoute)
                        return _buildCardScreen(context, route);
                    else if (route is CardListRoute) {
                        final params = route.params;
                        return new CardListScreen(params.storage, 
                            pack: params.pack, cardWasAdded: params.cardWasAdded);
                    }
                    else if (route is PackRoute) {
                        final params = route.params;
                        return new PackScreen(params.storage, 
                            packId: params.packId, packName: params.packName, 
                            refreshed: params.refreshed);
                    }
                    else if (route is StudyPreparerRoute)
                        return new StudyPreparerScreen(route.params.storage);
                    else if (route is StudyModeRoute) {
                        final params = route.params;
                        return new StudyScreen(params.storage, 
                            packIds: params.packIds, 
                            studyStageIds: params.studyStageIds);
                    }
                        
                    return new PackListScreen((route as PackListRoute).params.storage);
                })
            );
        });
    }

    void _updateState(_) => setState(() { });

    MaterialPageRoute _buildPageRoute(RouteSettings settings, 
        Widget Function(BuildContext, dynamic) builder) {

            final route = Router.getRoute(settings);
            return new MaterialPageRoute(
                settings: settings,
                builder: (inContext) => builder(inContext, route)
            );
        } 

    Widget _buildCardScreen(BuildContext context, WordCardRoute route) {
        final params = route.params;
        return new FutureLoader(Configuration.getParams(context), 
            (data) => new CardScreen(data.dictionary.apiKey, 
                wordStorage: params.storage, packStorage: params.packStorage,
                wordId: params.wordId, pack: params.pack));
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
