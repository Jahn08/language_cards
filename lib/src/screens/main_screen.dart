import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../consts.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../router.dart';
import '../data/quote_provider.dart';
import '../widgets/bar_scaffold.dart';
import '../widgets/empty_widget.dart';
import '../widgets/language_pair_selector.dart';
import '../widgets/one_line_text.dart';
import '../widgets/tight_flexible.dart';

class MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final quote = QuoteProvider.getNextQuote(locale);

    final languagePairsFuture = widget.packStorage.fetchLanguagePairs();

    final mediaQueryData = MediaQuery.of(context);
    return new BarScaffold.withSettings('Language Cards',
        barActions: [
          FutureBuilder(
              future: languagePairsFuture,
              builder: (context, langPairsSnapshot) {
                if (langPairsSnapshot.hasData)
                  return LanguagePairSelector(langPairsSnapshot.data!);

                return const EmptyWidget();
              })
        ],
        body: new Column(children: [
          _FlexibleRow(
              new Container(
                  width: mediaQueryData.size.width * 0.97,
                  child: new Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        new Text(quote.key,
                            textAlign: TextAlign.start,
                            maxLines: (4 / mediaQueryData.textScaler.scale(1)).round(),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: Consts.largeFontSize)),
                        new Text(quote.value,
                            textAlign: TextAlign.start,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: Consts.biggerFontSize))
                      ]),
                  padding: const EdgeInsets.all(10.0)),
              2),
          new _FlexibleRow(new _MenuItem(
              locale.mainScreenStudyModeMenuItemLabel,
              Consts.studyPreparationIcon,
              () => Router.goToStudyPreparation(context))),
          new _FlexibleRow(new _MenuItem(
              locale.mainScreenWordPacksMenuItemLabel,
              Consts.packListIcon,
              () => Router.goToPackList(context))),
          new _FlexibleRow(new _MenuItem(
              locale.mainScreenWordCardsMenuItemLabel,
              Consts.cardListIcon,
              () => Router.goToCardList(context, storage: widget.worStorage)))
        ]));
  }
}

class _FlexibleRow extends StatelessWidget {
  final Widget? child;

  final int? flex;

  const _FlexibleRow(this.child, [this.flex]);

  @override
  Widget build(BuildContext context) => new TightFlexible(
      child: new Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: child == null ? [] : [child!]),
      flex: flex);
}

class _MenuItem extends StatelessWidget {
  final String title;

  final IconData icon;

  final void Function() onClick;

  const _MenuItem(this.title, this.icon, this.onClick);

  @override
  Widget build(BuildContext context) => new Expanded(
      child: new Container(
          padding: const EdgeInsets.all(10),
          child: new ElevatedButton.icon(
              style: new ButtonStyle(
                  textStyle: WidgetStateProperty.resolveWith((states) =>
                      const TextStyle(fontSize: Consts.largeFontSize))),
              onPressed: onClick,
              icon: new Icon(icon),
              label: new OneLineText(title))));
}

class MainScreen extends StatefulWidget {
  final PackStorage packStorage;

  final WordStorage? worStorage;

  const MainScreen({PackStorage? packStorage, this.worStorage})
      : packStorage = packStorage ?? const PackStorage();

  @override
  State<StatefulWidget> createState() {
    return new MainScreenState();
  }
}
