import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../blocs/settings_bloc.dart';
import '../dialogs/single_selector_dialog.dart';
import '../models/user_params.dart';
import '../models/language.dart';
import 'loader.dart';
import 'translation_indicator.dart';

class LanguagePairSelector extends StatelessWidget {
  final Set<LanguagePair> _pairs;

  const LanguagePairSelector(this._pairs);

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    final futureParams = SettingsBlocProvider.of(context)?.userParams;
    return futureParams == null
        ? const SizedBox.shrink()
        : new FutureLoader(futureParams, (userParams) {
            final curLangPair = userParams.languagePair;

            if (curLangPair != null && !curLangPair.isEmpty)
              return IconButton(
                  icon: TranslationIndicator(curLangPair.from, curLangPair.to),
                  onPressed: () =>
                      showLanguagePairDialog(context, locale, userParams));

            if (_pairs.length < 2) return const SizedBox.shrink();

            return IconButton(
                icon: const Icon(Icons.flag_outlined),
                onPressed: () =>
                    showLanguagePairDialog(context, locale, userParams));
          });
  }

  Future<void> showLanguagePairDialog(BuildContext context,
      AppLocalizations locale, UserParams userParams) async {
    final langPairs = new List<LanguagePair>.from(_pairs);
    langPairs.add(LanguagePair.empty());

    final curLangPair = userParams.languagePair;
    if (curLangPair != null && !langPairs.contains(curLangPair))
      langPairs.add(curLangPair);

    langPairs.sort((a, b) => a.isEmpty
        ? -1
        : (b.isEmpty ? 1 : a.present(locale).compareTo(b.present(locale))));

    final chosenLangPair =
        await _LanguagePairSelectorDialog(context, curLangPair).show(langPairs);

    if (!context.mounted ||
        chosenLangPair == null ||
        curLangPair == chosenLangPair) return;

    userParams.languagePair = chosenLangPair.isEmpty ? null : chosenLangPair;
    await SettingsBlocProvider.of(context)!.save(userParams);
  }
}

class _LanguagePairSelectorDialog extends SingleSelectorDialog<LanguagePair> {
  final LanguagePair? _chosenPair;

  _LanguagePairSelectorDialog(BuildContext context, this._chosenPair)
      : super(context,
            AppLocalizations.of(context)!.languagePairSelectorDialogTitle,
            isShrunk: true);

  @override
  Widget getItemSubtitle(LanguagePair item) {
    final locale = AppLocalizations.of(context)!;
    if (item.isEmpty)
      return Text(locale.languagePairSelectorNoneLanguagePairName);

    return Text(item.present(locale));
  }

  @override
  Widget getItemTitle(LanguagePair item) => item.isEmpty
      ? const TranslationIndicator.empty()
      : new TranslationIndicator(item.from, item.to);

  @override
  Widget? getItemTrailing(LanguagePair item) {
    if (item == _chosenPair || (_chosenPair == null && item.isEmpty))
      return const Icon(Icons.check);

    return null;
  }
}
