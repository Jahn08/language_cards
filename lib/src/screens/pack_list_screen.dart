import 'package:flutter/material.dart' hide Router;
import './list_screen.dart';
import '../data/base_storage.dart';
import '../data/pack_storage.dart';
import '../dialogs/confirm_dialog.dart';
import '../router.dart';
import '../widgets/card_number_indicator.dart';
import '../widgets/one_line_text.dart';
import '../widgets/translation_indicator.dart';

class _PackListScreenState extends ListScreenState<StoredPack, PackListScreen> {

    @override
    Widget getItemLeading(StoredPack item) => 
        item.isNone ? new TranslationIndicator.empty():
            new TranslationIndicator(item.from, item.to);

    @override
    Widget getItemSubtitle(StoredPack item) => 
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
    void deleteItems(List<int> ids) => widget.storage.delete(ids);

	Future<bool> shouldContinueRemoval(List<StoredPack> itemsToRemove) async {
		final filledPackNames = itemsToRemove.where((p) => p.cardsNumber > 0)
			.map((p) => '"${p.name}"').toList();
		if (filledPackNames.isEmpty)
			return true;

		final jointNames = filledPackNames.join(', ');
		final outcome = await new ConfirmDialog(
			title: 'Removing Packs with Cards', 
			content: 'All the cards from $jointNames will be moved to the ${StoredPack.noneName} pack. Continue?', 
			confirmationLabel: 'Remove'
		).show(context);
		
		return outcome != null && outcome;
	}

    @override
    String get title => 'Card Packs';

    @override
    bool get canGoBack => true;

    @override
    void onGoingBack(BuildContext context) => Router.goHome(context);

    @override
    bool isRemovableItem(StoredPack item) => !item.isNone;

	@override
	Future<Map<String, int>> getFilterIndexes() => widget.storage.groupByTextIndex();
}

class PackListScreen extends ListScreen<StoredPack> {
    final BaseStorage<StoredPack> storage;

    PackListScreen(this.storage);

    @override
    _PackListScreenState createState() => new _PackListScreenState();
}
