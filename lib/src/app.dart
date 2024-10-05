import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import './blocs/settings_bloc.dart';
import './data/asset_dictionary_provider.dart';
import './models/user_params.dart';
import './router.dart';
import './screens/card_list_screen.dart';
import './screens/card_screen.dart';
import './screens/main_screen.dart';
import './screens/pack_list_screen.dart';
import './screens/pack_screen.dart';
import './screens/slider_screen.dart';
import './screens/study_screen.dart';
import './screens/study_preparer_screen.dart';
import './utilities/styler.dart';
import './widgets/loader.dart';
import 'data/word_storage.dart';

class App extends StatefulWidget {
  final PackStorage? packStorage;

  final WordStorage? wordStorage;

  const App({this.packStorage, this.wordStorage});

  @override
  AppState createState() => new AppState();
}

class AppState extends State<App> {
  SettingsBlocProvider? _blocProvider;

  @override
  Widget build(BuildContext context) =>
      _blocProvider ??= new SettingsBlocProvider(
          child: new _ThemedApp(
              packStorage: widget.packStorage,
              wordStorage: widget.wordStorage));
}

class _ThemedAppState extends State<_ThemedApp> {
  SettingsBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    if (_bloc == null) {
      _bloc = SettingsBlocProvider.of(context);
      _bloc!.addOnSaveListener(_updateState);
    }

    return new FutureLoader<UserParams>(_bloc!.userParams, (params) {
      ThemeData theme = params.theme == AppTheme.dark
          ? new ThemeData.dark(useMaterial3: false)
          : new ThemeData.light(useMaterial3: false);

      if (!new Styler(context).isWindowDense)
        theme = theme.copyWith(
            textTheme: theme.textTheme.copyWith(
                displayLarge:
                    _copyTextStyleAsScaled(theme.textTheme.displayLarge),
                displayMedium:
                    _copyTextStyleAsScaled(theme.textTheme.displayMedium),
                displaySmall:
                    _copyTextStyleAsScaled(theme.textTheme.displaySmall),
                headlineMedium:
                    _copyTextStyleAsScaled(theme.textTheme.headlineMedium),
                headlineSmall:
                    _copyTextStyleAsScaled(theme.textTheme.headlineSmall),
                titleLarge: _copyTextStyleAsScaled(theme.textTheme.titleLarge),
                titleMedium:
                    _copyTextStyleAsScaled(theme.textTheme.titleMedium),
                titleSmall: _copyTextStyleAsScaled(theme.textTheme.titleSmall),
                bodyLarge: _copyTextStyleAsScaled(theme.textTheme.bodyLarge),
                bodyMedium: _copyTextStyleAsScaled(theme.textTheme.bodyMedium),
                labelLarge: _copyTextStyleAsScaled(theme.textTheme.labelLarge),
                labelSmall:
                    _copyTextStyleAsScaled(theme.textTheme.labelSmall)));

      return new MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate
          ],
          locale: params.getLocale(),
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme,
          initialRoute: Router.initialRouteName,
          onGenerateRoute: (settings) =>
              _buildPageRoute(settings, (context, route) {
                if (route == null)
                  return MainScreen(
                      packStorage: widget.packStorage,
                      worStorage: widget.wordStorage);
                else if (route is WordCardRoute) {
                  final args = route.params;
                  return new CardScreen(
                      provider: new AssetDictionaryProvider(context),
                      wordStorage: args.storage,
                      packStorage: args.packStorage,
                      wordId: args.wordId,
                      languagePair: params.languagePair,
                      pack: args.pack);
                } else if (route is CardListRoute) {
                  final args = route.params;
                  return new CardListScreen(args.storage,
                      pack: args.pack,
                      packStorage: widget.packStorage,
                      refresh: args.refresh,
                      languagePair: params.languagePair);
                } else if (route is PackRoute) {
                  final params = route.params;
                  return new PackScreen(
                      params.storage, new AssetDictionaryProvider(context),
                      packId: params.packId, refresh: params.refresh);
                } else if (route is StudyPreparerRoute)
                  return new StudyPreparerScreen(
                      route.params.storage ?? widget.packStorage,
                      params.languagePair);
                else if (route is StudyModeRoute) {
                  final args = route.params;
                  return new StudyScreen(args.storage,
                      provider: new AssetDictionaryProvider(context),
                      packStorage: args.packStorage,
                      packs: args.packs,
                      languagePair: params.languagePair,
                      studyStageIds: args.studyStageIds);
                } else if (route is CardHelpRoute)
                  return const CardHelpScreen();
                else if (route is PackHelpRoute)
                  return const PackHelpScreen();
                else if (route is StudyHelpRoute)
                  return const StudyHelpScreen();

                final args = (route as PackListRoute).params;
                return new PackListScreen(
                    storage: args.storage ?? widget.packStorage,
                    languagePair: params.languagePair,
                    refresh: args.refresh);
              }));
    });
  }

  void _updateState(_) => setState(() {});

  TextStyle? _copyTextStyleAsScaled(TextStyle? original) =>
      original?.copyWith(fontSize: (original.fontSize ?? 14) * 1.3);

  MaterialPageRoute _buildPageRoute(
      RouteSettings settings, Widget Function(BuildContext, dynamic) builder) {
    final route = Router.getRoute(settings);
    return new MaterialPageRoute(
        settings: settings, builder: (inContext) => builder(inContext, route));
  }

  @override
  void dispose() {
    _bloc?.removeOnSaveListener(_updateState);

    super.dispose();
  }
}

class _ThemedApp extends StatefulWidget {
  final PackStorage? packStorage;

  final WordStorage? wordStorage;

  const _ThemedApp({this.packStorage, this.wordStorage});

  @override
  State<StatefulWidget> createState() => new _ThemedAppState();
}
