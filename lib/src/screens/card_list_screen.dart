import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../dialogs/confirm_dialog.dart';
import './list_screen.dart';
import '../models/word_study_stage.dart';
import '../router.dart';
import '../widgets/one_line_text.dart';

class _CardListScreenState extends ListScreenState<StoredWord, CardListScreen> {
    bool _cardsWereRemoved = false;

    @override
    Widget getItemSubtitle(StoredWord item) => new OneLineText(item.translation);
    
    @override
    Widget getItemTitle(StoredWord item) => new OneLineText(item.text);
    
    @override
    Widget getItemTrailing(StoredWord item) => new Column(children: <Widget>[
        if (item.partOfSpeech != null)
			new OneLineText(item.partOfSpeech.present(AppLocalizations.of(context))),
        new OneLineText('${item.studyProgress}%')
    ]);

    @override
    void onGoingToItem(BuildContext buildContext, [StoredWord item]) {
        super.onGoingToItem(buildContext, item);
        
        Router.goToCard(buildContext, wordId: item?.id, pack: widget.pack);
    }

    @override
    Future<List<StoredWord>> fetchNextItems(int skipCount, int takeCount, String text) =>
        widget.storage.fetchFiltered(skipCount: skipCount, takeCount: takeCount, 
            parentIds: _parentIds, text: text);
  
	List<int> get _parentIds => widget.pack == null ? null: [widget.pack.id];

    @override
    void deleteItems(List<StoredWord> items) {
        widget.storage.delete(items.map((i) => i.id).toList());

        _cardsWereRemoved = true;
    }

    @override
    String get title {
		final locale = AppLocalizations.of(context);
        final packName = widget.pack?.name;        
        return packName?.isEmpty ?? true ? locale.cardListScreenWithoutPackTitle: 
			locale.cardListScreenWithPackTitle(packName);
    }

    @override
    bool get canGoBack => true;

    @override
    void onGoingBack(BuildContext context) {
        final shouldRefreshPack = _cardsWereRemoved || widget.cardWasAdded;

        if (widget.pack == null)
            Router.goHome(context);
        else if (widget.pack.isNone)
            shouldRefreshPack ? Router.goToPackList(context) : 
                Router.goBackToPackList(context);
        else
            shouldRefreshPack ? 
                Router.goToPack(context, pack: widget.pack, refreshed: true): 
                Router.goBackToPack(context);
    }

    @override
    List<BottomNavigationBarItem> getNavBarOptions(bool allSelected, AppLocalizations locale) {
        final options = super.getNavBarOptions(allSelected, locale);
        options.add(new BottomNavigationBarItem(
            label: locale.cardListScreenBottomNavBarResettingProgressActionLabel,
            icon: new Icon(Icons.restore)
        ));

        return options;
    }

    @override
    Future<bool> handleNavBarOption(int tappedIndex, Iterable<StoredWord> markedItems,
        BuildContext scaffoldContext) async { 
		final locale = AppLocalizations.of(scaffoldContext);
        final itemsToReset = markedItems.where(
            (card) => card.studyProgress != WordStudyStage.unknown).toList();
        if (itemsToReset.length == 0 || !(await new ConfirmDialog(
				title: locale.cardListScreenResettingProgressDialogTitle,
				content: 
					locale.cardListScreenResettingProgressDialogContent(itemsToReset.length),
				confirmationLabel: 
					locale.cardListScreenResettingProgressDialogConfirmationButtonLabel)
			.show(scaffoldContext)))
            return false;

        setState(() {
            itemsToReset.forEach((w) => w.resetStudyProgress());
            widget.storage.update(itemsToReset);
        });

        Scaffold.of(scaffoldContext).showSnackBar(new SnackBar(
            content: new Text(
				locale.cardListScreenBottomSnackBarResettingProgressInfo(itemsToReset.length)
			)
		));
  
        return true;
    }

	@override
	Future<Map<String, int>> getFilterIndexes() => 
		widget.storage.groupByTextIndexAndParent(_parentIds);
}

class CardListScreen extends ListScreen<StoredWord> {
    final WordStorage storage;

    final StoredPack pack;

    final bool cardWasAdded;

    CardListScreen(this.storage, { this.pack, bool cardWasAdded }):
        cardWasAdded = cardWasAdded ?? false;

    @override
    _CardListScreenState createState() => new _CardListScreenState();
}
