import 'package:flutter/material.dart';
import 'package:language_cards/src/data/base_storage.dart';
import '../router.dart';
import '../data/word_storage.dart';
import './list_screen.dart';

class _MainScreenState extends ListScreenState<StoredWord> {

    @override
    String getItemSubtitle(StoredWord item) => item.translation;
    
    @override
    String getItemTitle(StoredWord item) => item.text;
    
    @override
    String getItemTrailing(StoredWord item) => item.partOfSpeech;

    @override
    void onLeaving(BuildContext buildContext, [StoredWord item]) {
        super.onLeaving(buildContext, item);
        
        Router.goToCard(buildContext, wordId: item?.id);
    }
}

class MainScreen extends ListScreen<StoredWord> {
    MainScreen(BaseStorage<StoredWord> storage): super(storage: storage);

    @override
    _MainScreenState createState() => new _MainScreenState();
}
