import 'package:flutter/material.dart';
import '../data/base_storage.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../dialogs/confirm_dialog.dart';
import './list_screen.dart';
import '../router.dart';

class _CardListScreenState extends ListScreenState<StoredWord, CardListScreen> {
    bool _cardsWereRemoved = false;

    @override
    Widget getItemSubtitle(StoredWord item) => super.buildOneLineText(item.translation);
    
    @override
    Widget getItemTitle(StoredWord item) => super.buildOneLineText(item.text);
    
    @override
    Widget getItemTrailing(StoredWord item) => new Column(children: <Widget>[
        super.buildOneLineText(item.partOfSpeech),
        super.buildOneLineText('${item.studyProgress}%')
    ]);

    @override
    void onGoingToItem(BuildContext buildContext, [StoredWord item]) {
        super.onGoingToItem(buildContext, item);
        
        Router.goToCard(buildContext, wordId: item?.id, pack: widget.pack);
    }

    @override
    Future<List<StoredWord>> fetchNextItems(int skipCount, int takeCount) =>
        widget.storage.fetch(skipCount: skipCount, takeCount: takeCount, 
            parentId: widget.pack?.id);
  
    @override
    void removeItems(List<int> ids) {
        widget.storage.delete(ids);

        _cardsWereRemoved = true;
    }

    @override
    String get title => widget.pack?.name ?? 'Word Cards';

    @override
    bool get canGoBack => true;

    @override
    void onGoingBack(BuildContext context) {
        final shouldRefreshPack = _cardsWereRemoved || widget.cardWasAdded;

        if (widget.pack != null && widget.pack.isNone)
            shouldRefreshPack ? Router.goToPackList(context) : 
                Router.goBackToPackList(context);
        else
            shouldRefreshPack ? 
                Router.goToPack(context, packId: widget.pack?.id, refreshed: true): 
                Router.goBackToPack(context);
    }

    @override
    List<BottomNavigationBarItem> getNavBarOptions(bool allSelected) {
        final options = super.getNavBarOptions(allSelected);
        options.add(new BottomNavigationBarItem(
            title: new Text('Reset Progress'),
            icon: new Icon(Icons.restore)
        ));

        return options;
    }

    @override
    Future<bool> handleNavBarOption(int tappedIndex, Iterable<StoredWord> markedItems,
        BuildContext scaffoldContext) async { 
        final listOfMarkedItems = markedItems.toList();
        if (listOfMarkedItems.length == 0 || !(await new ConfirmDialog(
            title: 'Confirm Resetting Study Progress', 
            content: 'The study progress of the ${listOfMarkedItems.length}' +
                ' marked cards will be reset. Continue?',
            actions: {
                true: 'Yes',   
                false: 'No'
            }).show(scaffoldContext)))
            return false;

        setState(() {
            listOfMarkedItems.forEach((w) => w.resetStudyProgress());
            widget.storage.update(listOfMarkedItems);
        });

        Scaffold.of(scaffoldContext).showSnackBar(new SnackBar(
            content: new Text('The study progress of the ${listOfMarkedItems.length}' + 
                ' cards has been reset')));
  
        return true;
    }
}

class CardListScreen extends StatefulWidget {
    final BaseStorage<StoredWord> storage;

    final StoredPack pack;

    final bool cardWasAdded;

    CardListScreen(this.storage, { this.pack, bool cardWasAdded }):
        cardWasAdded = cardWasAdded ?? false;

    @override
    _CardListScreenState createState() => new _CardListScreenState();
}
