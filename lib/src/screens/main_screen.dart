import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../consts.dart';
import '../router.dart';
import '../data/quote_provider.dart';
import '../widgets/bar_scaffold.dart';
import '../widgets/tight_flexible.dart';

class MainScreen extends StatelessWidget {

	MainScreen();

    @override
    Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
		final quote = QuoteProvider.getNextQuote(locale);
        
        return new BarScaffold.withSettings('Language Cards',
            body: new Column(
				children: [
					_FlexibleRow(new Container(
							width: MediaQuery.of(context).size.width * 0.97,
							child: new Column(
								mainAxisAlignment: MainAxisAlignment.center,
								crossAxisAlignment: CrossAxisAlignment.stretch,
								children: [
									new Text(
										quote.key,
										textAlign: TextAlign.start,
										style: TextStyle(fontSize: Consts.largeFontSize)
									),
									new Text(''),
									new Text(
										quote.value,
										textAlign: TextAlign.left,
										style: TextStyle(fontSize: Consts.biggerFontSize)
									)
								]
							),
							padding: EdgeInsets.all(10.0)
						), 2),
					new _FlexibleRow(new _MenuItem(
						locale.mainScreenStudyModeMenuItemLabel,
						Icons.school, 
						() => Router.goToStudyPreparation(context)
					)),
					new _FlexibleRow(new _MenuItem(
						locale.mainScreenWordPacksMenuItemLabel,
						Icons.library_books, 
						() => Router.goToPackList(context)
					)),
					new _FlexibleRow(new _MenuItem(
						locale.mainScreenWordCardsMenuItemLabel,
						Consts.cardListIcon, 
						() => Router.goToCardList(context)
					))
				]
        	)
        );
    }
}

class _FlexibleRow extends StatelessWidget {

	final Widget child;

	final int flex;

	_FlexibleRow(this.child, [this.flex]);

	@override
	Widget build(BuildContext context) =>
		new TightFlexible(
			child: new Row(
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: child == null ? []: [child]
            ),
			flex: flex
		);
}

class _MenuItem extends StatelessWidget {

	final String title;

	final IconData icon;

	final void Function() onClick;

	_MenuItem(this.title, this.icon, this.onClick);

	@override
	Widget build(BuildContext context) =>
        new Expanded(
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
