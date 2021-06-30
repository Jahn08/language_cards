import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../dialogs/confirm_dialog.dart';
import './list_screen.dart';
import '../models/word_study_stage.dart';
import '../router.dart';
import '../widgets/iconed_button.dart';
import '../widgets/one_line_text.dart';

class _CardListScreenState extends ListScreenState<StoredWord, CardListScreen> {
    bool _cardsWereRemoved = false;

    @override
    Widget getItemSubtitle(StoredWord item, { bool forCheckbox }) {
		final translationText = new OneLineText(item.translation);
		return (forCheckbox ?? false) ? 
			_buildCardAdditionalInfo(item, CrossAxisAlignment.start, translationText) : translationText;
	}
    
    @override
    Widget getItemTitle(StoredWord item) => new OneLineText(item.text);
    
    @override
    Widget getItemTrailing(StoredWord item) => _buildCardAdditionalInfo(item, CrossAxisAlignment.end);

	Widget _buildCardAdditionalInfo(StoredWord item, CrossAxisAlignment alignment, [Widget topItem]) {
		return new Column(
			crossAxisAlignment: alignment,
			children: <Widget>[
				if (topItem != null) 
					topItem,
				if (item.partOfSpeech != null)
					new OneLineText(item.partOfSpeech.present(AppLocalizations.of(context))),
				new OneLineText('${item.studyProgress}%')
			]
		);
	}

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
        final packName = widget.pack?.name;        
        return (packName?.isEmpty ?? true) ? 
			AppLocalizations.of(context).cardListScreenWithoutPackTitle: packName;
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
			Router.goToPack(context, pack: widget.pack, refreshed: shouldRefreshPack); 
    }

    @override
    List<Widget> getBottomBarOptions(
		List<StoredWord> markedItems, AppLocalizations locale, BuildContext scaffoldContext
	) {
        final options = super.getBottomBarOptions(markedItems, locale, scaffoldContext);
        return options..add(new IconedButton(
            label: locale.cardListScreenBottomNavBarResettingProgressActionLabel,
            icon: new Icon(Icons.restore),
			onPressed: () async {
				final itemsToReset = markedItems.where(
					(card) => card.studyProgress != WordStudyStage.unknown).toList();
				if (itemsToReset.length == 0 || !(await new ConfirmDialog(
						title: locale.cardListScreenResettingProgressDialogTitle,
						content: locale.cardListScreenResettingProgressDialogContent(
							itemsToReset.length.toString()),
						confirmationLabel: 
							locale.cardListScreenResettingProgressDialogConfirmationButtonLabel)
					.show(scaffoldContext)) ?? false)
					return false;

				setState(() {
					itemsToReset.forEach((w) => w.resetStudyProgress());
					widget.storage.upsert(itemsToReset);
				});

				ScaffoldMessenger.of(scaffoldContext).showSnackBar(new SnackBar(
					content: new Text(locale.cardListScreenBottomSnackBarResettingProgressInfo(
						itemsToReset.length.toString()))
				));
			
				super.clearItemsMarkedInEditor();
			}
        ));
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
