import 'package:flutter/material.dart';
import '../models/stored_pack.dart';
import './single_selector_dialog.dart';

class PackSelectorDialog extends SingleSelectorDialog<StoredPack> {

    PackSelectorDialog(BuildContext context): super(context, 'Choose a card pack');

    @override
    String getItemSubtitle(StoredPack item) => item.cardsNumber.toString();
  
    @override
    String getItemTitle(StoredPack item) => item.name;
}
