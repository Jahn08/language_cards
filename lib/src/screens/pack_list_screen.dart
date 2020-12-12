import 'package:flutter/material.dart' hide Router;
import '../data/base_storage.dart';
import '../data/pack_storage.dart';
import './list_screen.dart';
import '../router.dart';
import '../widgets/one_line_text.dart';
import '../widgets/translation_indicator.dart';

class _PackListScreenState extends ListScreenState<StoredPack, PackListScreen> {

    @override
    Widget getItemSubtitle(StoredPack item) => 
        item.isNone ? null: new TranslationIndicator(item.from, item.to);
    
    @override
    Widget getItemTitle(StoredPack item) => new OneLineText(item.name);
    
    @override
    Widget getItemTrailing(StoredPack item) => new Container(
        decoration: new BoxDecoration(
            borderRadius: new BorderRadius.all(new Radius.circular(5))
        ),
        child: new Text(item.cardsNumber.toString()),
    );

    @override
    void onGoingToItem(BuildContext buildContext, [StoredPack item]) {
        super.onGoingToItem(buildContext, item);
        
        item != null && item.isNone ? Router.goToCardList(context, pack: item): 
            Router.goToPack(buildContext, pack: item);
    }

    @override
    Future<List<StoredPack>> fetchNextItems(int skipCount, int takeCount) => 
        widget.storage.fetch(skipCount: skipCount, takeCount: takeCount);
  
    @override
    void removeItems(List<int> ids) => widget.storage.delete(ids);

    @override
    String get title => 'Card Packs';

    @override
    bool get canGoBack => true;

    @override
    void onGoingBack(BuildContext context) => Router.goHome(context);

    @override
    bool isRemovableItem(StoredPack item) => !item.isNone;
}

class PackListScreen extends StatefulWidget {
    final BaseStorage<StoredPack> storage;

    PackListScreen(this.storage);

    @override
    _PackListScreenState createState() => new _PackListScreenState();
}
