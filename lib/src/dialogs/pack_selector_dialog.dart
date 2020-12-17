import 'package:flutter/material.dart';
import '../models/stored_pack.dart';
import './single_selector_dialog.dart';
import '../widgets/card_number_indicator.dart';

class PackSelectorDialog extends SingleSelectorDialog<StoredPack> {
    int chosenPackId;

    PackSelectorDialog(BuildContext context, this.chosenPackId): 
        super(context, 'Choose a card pack');

    @override
    Widget getItemSubtitle(StoredPack item) => 
        new CardNumberIndicator(item.cardsNumber);
  
    @override
    String getItemTitle(StoredPack item) => item.name;

    @override
    Widget getItemTrailing(StoredPack item) => item.id == chosenPackId ? 
        new Icon(Icons.check): null;
}
