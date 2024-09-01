import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'single_selector_dialog.dart';
import '../models/stored_pack.dart';
import '../widgets/card_number_indicator.dart';
import '../widgets/translation_indicator.dart';

class PackSelectorDialog extends SingleSelectorDialog<StoredPack> {
  final int? _chosenPackId;

  PackSelectorDialog(BuildContext context, this._chosenPackId)
      : super(context, AppLocalizations.of(context)!.packSelectorDialogTitle);

  @override
  Widget getItemSubtitle(StoredPack item) =>
      new CardNumberIndicator(item.cardsNumber);

  @override
  Widget getItemTitle(StoredPack item) =>
      new Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ignore: prefer_if_elements_to_conditional_expressions
        item.isNone
            ? const TranslationIndicator.empty()
            : new TranslationIndicator(item.from, item.to),
        new Text(item.getLocalisedName(context))
      ]);

  @override
  Widget? getItemTrailing(StoredPack item) =>
      item.id == _chosenPackId ? const Icon(Icons.check) : null;
}
