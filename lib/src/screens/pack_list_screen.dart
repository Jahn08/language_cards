import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:language_cards/src/data/word_storage.dart';
import './list_screen.dart';
import '../data/base_storage.dart';
import '../data/pack_storage.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/import_dialog.dart';
import '../router.dart';
import '../utilities/pack_exporter.dart';
import '../widgets/card_number_indicator.dart';
import '../widgets/iconed_button.dart';
import '../widgets/one_line_text.dart';
import '../widgets/translation_indicator.dart';

class _PackListScreenState extends ListScreenState<StoredPack, PackListScreen> {

    @override
    Widget getItemLeading(StoredPack item) => 
        item.isNone ? new TranslationIndicator.empty():
            new TranslationIndicator(item.from, item.to);

    @override
    Widget getItemSubtitle(StoredPack item, { bool forCheckbox }) => 
        new CardNumberIndicator(item.cardsNumber);
    
    @override
    Widget getItemTitle(StoredPack item) => new OneLineText(item.name);
    
    @override
    void onGoingToItem(BuildContext buildContext, [StoredPack item]) {
        super.onGoingToItem(buildContext, item);
        
        item != null && item.isNone ? Router.goToCardList(context, pack: item): 
            Router.goToPack(buildContext, pack: item);
    }

    @override
    Future<List<StoredPack>> fetchNextItems(int skipCount, int takeCount, String text) => 
        widget.storage.fetch(skipCount: skipCount, takeCount: takeCount, textFilter: text);
  
    @override
    void deleteItems(List<StoredPack> items) {
		widget.storage.delete(items.map((i) => i.id).toList()).then((res) {
			final untiedCardsNumber = items.map((i) => i.cardsNumber)
				.fold(0, (prev, el) => prev + el);
			if (untiedCardsNumber > 0)
				setState(() => StoredPack.none.cardsNumber += untiedCardsNumber);
		});
	}

	Future<bool> shouldContinueRemoval(List<StoredPack> itemsToRemove) async {
		final filledPackNames = itemsToRemove.where((p) => p.cardsNumber > 0)
			.map((p) => '"${p.name}"').toList();
		if (filledPackNames.isEmpty)
			return true;

		final locale = AppLocalizations.of(context);
		final jointNames = filledPackNames.join(', ');
		final content = locale.packListScreenRemovingNonEmptyPacksDialogContent(
			jointNames, StoredPack.noneName);
		final outcome = await new ConfirmDialog(
			title: locale.packListScreenRemovingNonEmptyPacksDialogTitle, 
			content: content, 
			confirmationLabel: locale.constsRemovingItemButtonLabel
		).show(context);
		
		return outcome != null && outcome;
	}

    @override
    String get title => AppLocalizations.of(context).packListScreenTitle;

    @override
    bool get canGoBack => true;

    @override
    void onGoingBack(BuildContext context) => Router.goHome(context);

    @override
    bool isRemovableItem(StoredPack item) => !item.isNone;

	@override
	Future<Map<String, int>> getFilterIndexes() => widget.storage.groupByTextIndex();

	@override
    List<Widget> getBottomBarOptions(
		List<StoredPack> markedItems, AppLocalizations locale, BuildContext scaffoldContext
	) {
        final options = super.getBottomBarOptions(markedItems, locale, scaffoldContext);
        return options..add(new IconedButton(
            label: markedItems.isEmpty ? 
				locale.packListScreenBottomNavBarImportActionLabel:
				locale.packListScreenBottomNavBarExportActionLabel,
            icon: new Icon(Icons.import_export),
			onPressed: () async {
				if (markedItems.isEmpty) {
					final outcome = await new ImportDialog(widget.storage, widget.cardStorage)
						.show(scaffoldContext);

					if (outcome == null)
						return true;
					else if (outcome.packsWithCards == null) {
						await new ConfirmDialog.ok(
							title: locale.packListScreenImportDialogTitle,
							content: locale.packListScreenImportDialogWrongFormatContent(outcome.filePath)
						).show(scaffoldContext);
						return true;
					}

					final packsWithCards = outcome.packsWithCards;
					await new ConfirmDialog.ok(
						title: locale.packListScreenImportDialogTitle,
						content: locale.packListScreenImportDialogContent(packsWithCards.keys.length, 
							packsWithCards.values.expand((c) => c).length, outcome.filePath)
					).show(scaffoldContext);

					super.refetchItems(isForceful: true, shouldInitIndices: true);
				}
				else {
					final exportFilePath = await new PackExporter(widget.cardStorage)
						.export(markedItems.toList(), 'packs');

					await new ConfirmDialog.ok(
						title: locale.packListScreenExportDialogTitle,
						content: locale.packListScreenExportDialogContent(exportFilePath)
					).show(scaffoldContext);
				}

				super.clearItemsMarkedIneditor();
			}
        ));
    }
}

class PackListScreen extends ListScreen<StoredPack> {
    final BaseStorage<StoredPack> storage;

    final BaseStorage<StoredWord> cardStorage;

    PackListScreen(this.storage, this.cardStorage);

    @override
    _PackListScreenState createState() => new _PackListScreenState();
}
