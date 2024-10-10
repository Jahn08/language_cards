import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:language_cards/src/models/language.dart';
import '../utilities/pack_importer.dart';
import './list_screen.dart';
import '../data/pack_storage.dart';
import '../data/word_storage.dart';
import '../dialogs/confirm_dialog.dart';
import '../dialogs/import_dialog.dart';
import '../dialogs/loader_dialog.dart';
import '../router.dart';
import '../utilities/pack_exporter.dart';
import '../widgets/card_number_indicator.dart';
import '../widgets/iconed_button.dart';
import '../widgets/one_line_text.dart';
import '../widgets/translation_indicator.dart';

class _PackListScreenState extends ListScreenState<StoredPack, PackListScreen> {
  Set<int?>? _nonRemovableItemIds;

  bool packsDeleted = false;

  final _nonPackCardsNumberNotifier = new ValueNotifier<int?>(null);

  @override
  void dispose() {
    _nonPackCardsNumberNotifier.dispose();

    super.dispose();
  }

  @override
  Widget getItemLeading(StoredPack item) => item.isNone
      ? const TranslationIndicator.empty()
      : new TranslationIndicator(item.from, item.to);

  @override
  Widget getItemSubtitle(StoredPack item, {bool forCheckbox = false}) {
    if (item.isNone) {
      _nonPackCardsNumberNotifier.value ??= item.cardsNumber;
      return new ValueListenableBuilder(
          valueListenable: _nonPackCardsNumberNotifier,
          builder: (_, int? nonPackCardsNumber, __) =>
              new CardNumberIndicator(nonPackCardsNumber));
    }

    return new CardNumberIndicator(item.cardsNumber);
  }

  @override
  Widget getItemTitle(StoredPack item) =>
      new OneLineText(item.getLocalisedName(context));

  @override
  void onGoingToItem(BuildContext buildContext, [StoredPack? item]) {
    super.onGoingToItem(buildContext, item);

    item != null && item.isNone
        ? Router.goToCardList(context, pack: item)
        : Router.goToPack(buildContext, pack: item, storage: widget.storage);
  }

  @override
  Future<List<StoredPack>> fetchNextItems(
      int skipCount, int takeCount, String? text) async {
    if (skipCount > 0) return Future.value([]);

    return widget.storage
        .fetch(textFilter: text, languagePair: widget.languagePair);
  }

  @override
  void deleteItems(List<StoredPack> items) {
    if (items.isEmpty) return;

    widget.storage.delete(items.map((i) => i.id!).toList()).then((res) {
      final untiedCardsNumber =
          items.map((i) => i.cardsNumber).fold<int>(0, (prev, el) => prev + el);
      if (untiedCardsNumber > 0) {
        StoredPack.none.cardsNumber += untiedCardsNumber;
        _nonPackCardsNumberNotifier.value = StoredPack.none.cardsNumber;
      }
    });

    packsDeleted = true;
  }

  @override
  Future<bool> shouldContinueRemoval(List<StoredPack> itemsToRemove) async {
    final filledPackNames = itemsToRemove
        .where((p) => p.cardsNumber > 0)
        .map((p) => '"${p.name}"')
        .toList();
    if (filledPackNames.isEmpty) return true;

    filledPackNames.sort((a, b) => a.compareTo(b));
    final locale = AppLocalizations.of(context)!;

    const String newLine = '\n';
    final joinedNames =
        '${filledPackNames.length > 1 ? locale.constsPackPluralForm : ''}$newLine' +
            filledPackNames.join(',$newLine');
    final content = locale.packListScreenRemovingNonEmptyPacksDialogContent(
        joinedNames, locale.storedPackNonePackName);
    final outcome = await new ConfirmDialog(
            title: locale.packListScreenRemovingNonEmptyPacksDialogTitle,
            content: content,
            confirmationLabel: locale.constsRemovingItemButtonLabel)
        .show(context);

    return outcome != null && outcome;
  }

  @override
  String get title => AppLocalizations.of(context)!.packListScreenTitle;

  @override
  bool get canGoBack => true;

  @override
  void onGoingBack(BuildContext context) =>
      Router.returnHome(context, refresh: widget.refresh || packsDeleted);

  @override
  int get removableItemsLength =>
      super.removableItemsLength -
      (super.curFilterIndex == null ? nonRemovableItemIds.length : 0);

  @override
  Set<int?> get nonRemovableItemIds => _nonRemovableItemIds ??=
      super.nonRemovableItemIds..add(StoredPack.none.id);

  @override
  Future<Map<String, int>> getFilterIndexes() =>
      widget.storage.groupByTextIndex();

  @override
  List<Widget> getBottomBarOptions(List<StoredPack> markedItems,
      AppLocalizations locale, BuildContext scaffoldContext) {
    final options =
        super.getBottomBarOptions(markedItems, locale, scaffoldContext);
    return options
      ..add(new IconedButton(
          label: markedItems.isEmpty
              ? locale.packListScreenBottomNavBarImportActionLabel
              : locale.packListScreenBottomNavBarExportActionLabel,
          icon: const Icon(Icons.import_export),
          onPressed: () async {
            try {
              if (markedItems.isEmpty) {
                final filePath =
                    await const ImportDialog().show(scaffoldContext);
                if (!scaffoldContext.mounted) return;

                if (filePath == null) return;

                final importState = await LoaderDialog.showAsync<
                        Map<StoredPack, List<StoredWord>>>(
                    scaffoldContext,
                    () => new PackImporter(
                            widget.storage, widget.cardStorage, locale)
                        .import(filePath),
                    locale);
                if (!scaffoldContext.mounted) return;

                if (importState!.error != null) throw importState.error!;

                final packsWithCards = importState.value!;
                await new ConfirmDialog.ok(
                        title: locale.packListScreenImportDialogTitle,
                        content: locale.packListScreenImportDialogContent(
                            packsWithCards.keys.length.toString(),
                            packsWithCards.values
                                .expand((c) => c)
                                .length
                                .toString(),
                            filePath))
                    .show(scaffoldContext);

                await super
                    .refetchItems(isForceful: true, shouldInitIndices: true);
              } else {
                final exportState = await LoaderDialog.showAsync<String>(
                    scaffoldContext,
                    () => new PackExporter(widget.cardStorage)
                        .export(markedItems.toList(), 'packs', locale),
                    locale);
                if (!scaffoldContext.mounted) return;

                if (exportState!.error != null) throw exportState.error!;

                final exportFilePath = exportState.value!;
                await new ConfirmDialog.ok(
                        title: locale.packListScreenExportDialogTitle,
                        content: locale.packListScreenExportDialogContent(
                            exportFilePath.replaceFirst(
                                new RegExp('^.*Download'), 'Downloads')))
                    .show(scaffoldContext);
              }
            } catch (error) {
              String errMessage;
              if (error is ImportException)
                errMessage =
                    locale.packListScreenImportDialogWrongFormatContent(
                        error.importFilePath);
              else if (error is FileSystemException)
                errMessage = error.message;
              else
                errMessage = error.toString();

              await new ConfirmDialog.ok(
                      title: locale.importExportWarningDialogTitle,
                      content: errMessage)
                  // ignore: use_build_context_synchronously
                  .show(context);

              if (!Platform.environment.containsKey('FLUTTER_TEST')) rethrow;
            }
          }));
  }
}

class PackListScreen extends ListScreen<StoredPack> {
  @override
  final PackStorage storage;

  final WordStorage cardStorage;

  final LanguagePair? languagePair;

  final bool refresh;

  const PackListScreen(
      {PackStorage? storage,
      WordStorage? cardStorage,
      this.languagePair,
      this.refresh = false})
      : storage = storage ?? const PackStorage(),
        cardStorage = cardStorage ?? const WordStorage(),
        super();

  @override
  _PackListScreenState createState() => new _PackListScreenState();
}
