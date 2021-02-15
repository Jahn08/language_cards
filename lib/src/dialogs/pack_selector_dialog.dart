import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'single_selector_dialog.dart';
import '../models/stored_pack.dart';
import '../widgets/card_number_indicator.dart';

class PackSelectorDialog extends SingleSelectorDialog<StoredPack> {
    int chosenPackId;

    PackSelectorDialog(BuildContext context, this.chosenPackId): 
        super(context, AppLocalizations.of(context).packSelectorDialogTitle);

    @override
    Widget getItemSubtitle(StoredPack item) => 
        new CardNumberIndicator(item.cardsNumber);
  
    @override
    String getItemTitle(StoredPack item) => item.name;

    @override
    Widget getItemTrailing(StoredPack item) => item.id == chosenPackId ? 
        new Icon(Icons.check): null;
}
