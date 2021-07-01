import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart' hide Router;
import 'package:language_cards/src/data/configuration.dart';
import 'package:language_cards/src/router.dart';
import 'package:language_cards/src/screens/card_list_screen.dart';
import 'package:language_cards/src/screens/main_screen.dart';
import 'package:language_cards/src/screens/pack_list_screen.dart';
import 'package:language_cards/src/screens/pack_screen.dart';
import '../utilities/randomiser.dart';
import 'dictionary_provider_mock.dart';
import 'pack_storage_mock.dart';

class RootWidgetMock extends StatelessWidget {
    final Widget _child;
    
    final Function(BuildContext) _onBuildCallback;

    final bool _noBar;

    RootWidgetMock({ Function(BuildContext) onBuilding, Widget child, bool noBar }):
        _onBuildCallback = onBuilding,
        _child = child,
        _noBar = noBar ?? false;

    @override
    Widget build(BuildContext context) {
        if (_onBuildCallback != null)
            _onBuildCallback(context);

        return _noBar ? _child: new Scaffold(
            appBar: new AppBar(
                title: new Text('Test Widget'),
            ),
            body: new Container(
                child: _child
            )
        );
    }

	static Widget buildAsAppHome({ 
		Function(BuildContext) onBuilding, 
		Widget child, 
		Widget Function(BuildContext) childBuilder,
		bool noBar 
	}) => _buildAsAppHome((settings) => new MaterialPageRoute(
			builder: (context) => new RootWidgetMock(
				onBuilding: onBuilding, 
				child: childBuilder?.call(context) ?? child, 
				noBar: noBar
			)
		));

    static Widget _buildAsAppHome(Route<dynamic> Function(RouteSettings) onGenerateRoute) => 
		new MaterialApp(
			localizationsDelegates: [
				AppLocalizations.delegate,
				GlobalMaterialLocalizations.delegate,
				GlobalWidgetsLocalizations.delegate
			],
			initialRoute: Router.initialRouteName,
			onGenerateRoute: onGenerateRoute
		);

	static Widget buildAsAppHomeWithRouting({ 
		@required PackStorageMock storage, 
		@required PackListScreen Function() packListScreenBuilder, 
		String packName, bool cardWasAdded, bool noBar
	}) => RootWidgetMock._buildAsAppHome((settings) {
		final route = Router.getRoute(settings);

		if (route == null)
			return new MaterialPageRoute(
				settings: settings,
				builder: (context) => new RootWidgetMock(
					noBar: noBar,
					child: new MainScreen(new ContactsParams(
						fbUserId: Randomiser.nextString()
					))
				)
			);
		if (route is CardListRoute)
			return new MaterialPageRoute(
				settings: settings,
				builder: (context) => new RootWidgetMock(
					noBar: noBar,
					child: new CardListScreen(storage.wordStorage, pack: route.params.pack, 
						cardWasAdded: cardWasAdded))
			);
		else if (route is PackRoute)
			return new MaterialPageRoute(
				settings: settings,
				builder: (context) => new RootWidgetMock(
					noBar: noBar,
					child: new PackScreen(storage, new DictionaryProviderMock(), 
						packId: route.params.packId, refreshed: route.params.refreshed))
			);

		return new MaterialPageRoute(
			settings: settings,
			builder: (context) => new RootWidgetMock(
				noBar: noBar,
				child: packListScreenBuilder.call()
			)
		);
	});
}
