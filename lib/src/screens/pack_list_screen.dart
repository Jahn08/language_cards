import 'package:flutter/material.dart';
import '../data/base_storage.dart';
import '../data/pack_storage.dart';
import '../widgets/asset_icon.dart';
import '../widgets/icon_option.dart';
import './list_screen.dart';
import '../router.dart';

class _PackListScreenState extends ListScreenState<StoredPack, PackListScreen> {

    @override
    Widget getItemSubtitle(StoredPack item) => item.isNone ? null: new Row(
        children: <Widget>[
            new IconOption(icon: AssetIcon.buildByLanguage(item.from)),
            new Icon(Icons.arrow_right),
            new IconOption(icon: AssetIcon.buildByLanguage(item.to))
        ]
    );
    
    @override
    Widget getItemTitle(StoredPack item) => super.buildOneLineText(item.name);
    
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
    bool get showSettings => true;

    @override
    String get title => 'Card Packs';

    @override
    bool get canGoBack => false;

    @override
    void onGoingBack(BuildContext context) {}

    @override
    bool isRemovableItem(StoredPack item) => !item.isNone;
}

class PackListScreen extends StatefulWidget {
    final BaseStorage<StoredPack> storage;

    PackListScreen(this.storage);

    @override
    _PackListScreenState createState() => new _PackListScreenState();
}
