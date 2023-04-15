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

	int _loadedItemsCount;

    @override
    Widget getItemSubtitle(StoredWord item, { bool forCheckbox }) {
		final translationText = new OneLineText(item.translation);
		return (forCheckbox ?? false) ? 
			new _CardAdditionalInfo(item, CrossAxisAlignment.start, translationText) : translationText;
	}
    
    @override
    Widget getItemTitle(StoredWord item) => new OneLineText(item.text);
    
    @override
    Widget getItemTrailing(StoredWord item) => new _CardAdditionalInfo(item, CrossAxisAlignment.end);

    @override
    void onGoingToItem(BuildContext buildContext, [StoredWord item]) {
        super.onGoingToItem(buildContext, item);
        
        Router.goToCard(buildContext, wordId: item?.id, pack: widget.pack);
    }

    @override
    Future<List<StoredWord>> fetchNextItems(int skipCount, int takeCount, String text) async {
        final items = await widget.storage.fetchFiltered(skipCount: skipCount, takeCount: takeCount, 
            parentIds: _parentIds, text: text);
			
		if (items.isNotEmpty)
			_loadedItemsCount = skipCount + items.length;
		
		return items;
	}

	List<int> get _parentIds => widget.pack == null ? null: [widget.pack.id];

    @override
    void deleteItems(List<StoredWord> items) {
		if (items.isEmpty)
			return;
			
        widget.storage.delete(items.map((i) => i.id).toList());
        _cardsWereRemoved = true;
    }

	@override
	Future<void> updateStateAfterDeletion() async {
		_loadedItemsCount = 0;
		await refetchItems(text: super.curFilterIndex, isForceful: true);

		if (_loadedItemsCount == 0)
			await super.updateStateAfterDeletion();
	}

    @override
    String get title {
        final packName = widget.pack?.getLocalisedName(context);        
        return (packName?.isEmpty ?? true) ? 
			AppLocalizations.of(context).cardListScreenWithoutPackTitle: packName;
    }

    @override
    bool get canGoBack => true;

    @override
    void onGoingBack(BuildContext context) {
        final shouldRefreshPack = _cardsWereRemoved || widget.refresh;

        if (widget.pack == null)
            Router.returnHome(context);
        else if (widget.pack.isNone)
			Router.goBackToPackList(context, refresh: shouldRefreshPack);
        else
			Router.goBackToPack(context, pack: widget.pack, refresh: shouldRefreshPack);
    }

    @override
    List<Widget> getBottomBarOptions(
		List<StoredWord> markedItems, AppLocalizations locale, BuildContext scaffoldContext
	) {
        final options = super.getBottomBarOptions(markedItems, locale, scaffoldContext);
        return options..add(new IconedButton(
            label: locale.cardListScreenBottomNavBarResettingProgressActionLabel,
            icon: const Icon(Icons.restore),
			onPressed: () async {
				final itemsToReset = markedItems.where(
					(card) => card.studyProgress != WordStudyStage.unknown).toList();
				if (itemsToReset.isEmpty || !(await new ConfirmDialog(
						title: locale.cardListScreenResettingProgressDialogTitle,
						content: locale.cardListScreenResettingProgressDialogContent(
							itemsToReset.length.toString()),
						confirmationLabel: 
							locale.cardListScreenResettingProgressDialogConfirmationButtonLabel)
					.show(scaffoldContext)) ?? false)
					return;

				itemsToReset.forEach((w) => w.resetStudyProgress());
				await widget.storage.upsert(itemsToReset);

				await refetchItems(isForceful: true);

				if (!mounted)
					return;

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

	@override
	String getSelectorBtnLabel({ bool allSelected, AppLocalizations locale }) {
		final itemsOverall = super.filterIndexLength;
		if (_loadedItemsCount == itemsOverall)
			return super.getSelectorBtnLabel(allSelected: allSelected, locale: locale);

		return allSelected ? 
			locale.constsUnselectSome(_loadedItemsCount.toString(), itemsOverall.toString()): 
			locale.constsSelectSome(_loadedItemsCount.toString(), itemsOverall.toString()); 
	}
}

class _CardAdditionalInfo extends StatelessWidget {

	final StoredWord card;

	final CrossAxisAlignment alignment;
	
	final Widget topItem;

	const _CardAdditionalInfo(this.card, this.alignment, [this.topItem]);

	@override
	Widget build(BuildContext context) =>
		new Column(
			crossAxisAlignment: alignment,
			children: <Widget>[
				if (topItem != null) 
					topItem,
				if (card.partOfSpeech != null)
					new OneLineText(card.partOfSpeech.present(AppLocalizations.of(context))),
				new OneLineText('${card.studyProgress}%')
			]
		);
}

class CardListScreen extends ListScreen<StoredWord> {
	@override
    final WordStorage storage;

    final StoredPack pack;

    final bool refresh;

    const CardListScreen(this.storage, { this.pack, bool refresh }):
        refresh = refresh ?? false,
		super();

    @override
    _CardListScreenState createState() => new _CardListScreenState();
}
