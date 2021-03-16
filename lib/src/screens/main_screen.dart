import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../consts.dart';
import '../router.dart';
import '../models/app_params.dart';
import '../widgets/bar_scaffold.dart';

class MainScreen extends StatelessWidget {

	final ContactsParams params;

	MainScreen(this.params);

    @override
    Widget build(BuildContext context) {

        return new BarScaffold.withSettings('Language Cards',
			contactsParams: params,
            body: _buildMenu(context),
        );
    }

    Widget _buildMenu(BuildContext context) {
		final locale = AppLocalizations.of(context);
        return new Column(
            children: [
                _buildRow(flex: 2),
                _buildRow(child: _buildMenuItem(
					locale.mainScreenStudyModeMenuItemLabel,
					Icons.school, 
					() => Router.goToStudyPreparation(context)
				)),
                _buildRow(child: _buildMenuItem(
					locale.mainScreenWordPacksMenuItemLabel,
					Icons.library_books, 
                  	() => Router.goToPackList(context)
				)),
                _buildRow(child: _buildMenuItem(
					locale.mainScreenWordCardsMenuItemLabel,
					Consts.cardListIcon, 
                  	() => Router.goToCardList(context)
				))
            ]
        );
    }

    Widget _buildRow({ Widget child, int flex }) => 
        new Flexible(
            fit: FlexFit.tight,
            flex: flex ?? 1,
            child: new Row(
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: child == null ? []: [child]
            )
        );

    Widget _buildMenuItem(String title, IconData icon, void Function() onClick) {
        return new Expanded(
            child: new Container(
                padding: EdgeInsets.all(10),
                child: new ElevatedButton.icon(
                    style: new ButtonStyle(
                        textStyle: MaterialStateProperty.resolveWith(
                            (states) => new TextStyle(
                                fontSize: Consts.largeFontSize
                            )) 
                    ),
                    onPressed: onClick, 
                    icon: new Icon(icon), 
                    label: new Text(title)
                )
            )
        );
    }
}
