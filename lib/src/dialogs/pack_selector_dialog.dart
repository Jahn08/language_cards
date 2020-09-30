import 'package:flutter/material.dart';
import '../models/stored_pack.dart';
import './single_selector_dialog.dart';

class PackSelectorDialog extends SingleSelectorDialog<StoredPack> {
    int chosenPackId;

    PackSelectorDialog(BuildContext context, this.chosenPackId): 
        super(context, 'Choose a card pack');

    @override
    String getItemSubtitle(StoredPack item) => '${item.cardsNumber.toString()} Cards';
  
    @override
    String getItemTitle(StoredPack item) => item.name;

    @override
    Widget getItemTrailing(StoredPack item) => item.id == chosenPackId ? 
        new Icon(Icons.check): null;
}
