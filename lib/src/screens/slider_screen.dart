import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../dialogs/confirm_dialog.dart';
import '../models/presentable_enum.dart';
import '../models/user_params.dart';
import '../utilities/local_asset_image.dart';
import '../utilities/string_ext.dart';
import '../utilities/styler.dart';
import '../widgets/bar_scaffold.dart';

class _SliderScreenState extends State<_SliderScreen> {
  final _pageIndexNotifier = new ValueNotifier<int>(0);

  List<Widget>? _slides;

  late PageController _ctrl;

  @override
  void initState() {
    super.initState();

    _ctrl = new PageController();
  }

  @override
  void dispose() {
    _ctrl.dispose();

    _pageIndexNotifier.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    _slides ??= widget.slideNames
        .map((n) => _buildSlide(new Image(
            image: new LocalAssetImage(n,
                localeName: locale.localeName, fileExtension: 'png'))))
        .toList();

    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showInfoDialog(context, locale));
    return new BarScaffold(
      titleWidget: new ValueListenableBuilder(
          valueListenable: _pageIndexNotifier,
          builder: (_, __, ___) => new BarTitle(_compileTitle(locale))),
      body: new Container(
          child: new PageView(
              controller: _ctrl,
              allowImplicitScrolling: true,
              children: _slides!,
              onPageChanged: (pageIndex) {
                _pageIndexNotifier.value = pageIndex;
                _showInfoDialog(context, locale);
              }),
          margin: const EdgeInsets.all(5.0),
          decoration: new BoxDecoration(
              border: new Border.all(color: new Styler(context).primaryColor))),
      barActions: [
        new IconButton(
            onPressed: () => _showInfoDialog(context, locale),
            icon: const Icon(Icons.info))
      ],
    );
  }

  String _compileTitle(AppLocalizations locale) =>
      '${widget.getTitle(locale)}\n' +
      locale.helpScreenPageIndicator(
          _pageIndexNotifier.value + 1, _slides!.length);

  Widget _buildSlide(Image image) {
    const double iconSize = 30;
    return new Stack(
      fit: StackFit.expand,
      children: [
        new Container(child: image, alignment: Alignment.center),
        new Container(
            alignment: Alignment.centerRight,
            child: new ValueListenableBuilder(
                valueListenable: _pageIndexNotifier,
                child: const Icon(Icons.chevron_right_outlined),
                builder: (_, pageIndex, icon) => new IconButton(
                    icon: icon!,
                    onPressed: pageIndex == _slides!.length - 1
                        ? null
                        : () => _ctrl.nextPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut),
                    iconSize: iconSize))),
        new Container(
            alignment: Alignment.centerLeft,
            child: new ValueListenableBuilder(
                valueListenable: _pageIndexNotifier,
                child: const Icon(Icons.chevron_left_outlined),
                builder: (_, pageIndex, icon) => new IconButton(
                    icon: icon!,
                    onPressed: pageIndex == 0
                        ? null
                        : () => _ctrl.previousPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut),
                    iconSize: iconSize)))
      ],
    );
  }

  Future<void> _showInfoDialog(
      BuildContext context, AppLocalizations locale) async {
    final description = widget.descriptor(_pageIndexNotifier.value, locale);

    final parts = splitLocalizedText(description);
    await new ConfirmDialog.ok(title: parts.last, content: parts.first)
        .show(context);
  }
}

abstract class _SliderScreen extends StatefulWidget {
  final List<String> slideNames;

  final String Function(int slideIndex, AppLocalizations locale) descriptor;

  const _SliderScreen(this.slideNames, this.descriptor);

  @override
  State<StatefulWidget> createState() => new _SliderScreenState();

  @protected
  String getTitle(AppLocalizations locale);

  @protected
  static Exception createSlideDescriptionNotFoundError(int slideIndex) =>
      new Exception('No description is found for slide #$slideIndex');
}

class CardHelpScreen extends _SliderScreen {
  const CardHelpScreen()
      : super(const [
          'help_card_screen',
          'help_card_editor',
          'help_card_unlearning',
          'help_card_removal',
          'help_card_adding',
          'help_card_word_text',
          'help_card_word_dictionary',
          'help_card_word_translation',
          'help_card_saving',
          'help_card_duplicate',
          'help_card_translation_merge',
          'help_card_search'
        ], _descriptor);

  @override
  String getTitle(AppLocalizations locale) =>
      locale.helpScreenTitle(locale.mainScreenWordCardsMenuItemLabel);

  static String _descriptor(int slideIndex, AppLocalizations locale) {
    switch (slideIndex) {
      case 0:
        return locale.helpCardScreenOverviewSlideDescription;
      case 1:
        return locale.helpListScreenEditorSlideDescription;
      case 2:
        return locale.helpCardScreenUnlearningSlideDescription(
            locale.cardListScreenBottomNavBarResettingProgressActionLabel);
      case 3:
        return locale.helpCardScreenRemovingSlideDescription(
            locale.constsRemovingItemButtonLabel,
            locale.listScreenBottomSnackBarUndoingActionLabel);
      case 4:
        return locale.helpCardScreenAddingSlideDescription(
            locale.storedPackNonePackName);
      case 5:
        return locale.helpCardScreenWordTextSlideDescription;
      case 6:
        return locale.helpCardScreenWordDictionarySlideDescription;
      case 7:
        return locale.helpCardScreenWordTranslationSlideDescription;
      case 8:
        return locale.helpCardScreenSavingSlideDescription(
            locale.translationSelectorDoneButtonLabel,
            locale.constsSavingItemButtonLabel);
      case 9:
        return locale.helpCardScreenDuplicateDescription;
      case 10:
        return locale.helpCardScreenTranslationMergeDescription;
      case 11:
        return locale.helpCardScreenSearchSlideDescription;
      default:
        throw _SliderScreen.createSlideDescriptionNotFoundError(slideIndex);
    }
  }
}

class PackHelpScreen extends _SliderScreen {
  const PackHelpScreen()
      : super(const [
          'help_pack_screen',
          'help_pack_editor',
          'help_pack_export',
          'help_pack_import',
          'help_pack_removal',
          'help_pack_card_relocation',
          'help_pack_adding',
          'help_pack_amending',
          'help_pack_search'
        ], _descriptor);

  @override
  String getTitle(AppLocalizations locale) =>
      locale.helpScreenTitle(locale.mainScreenWordPacksMenuItemLabel);

  static String _descriptor(int slideIndex, AppLocalizations locale) {
    switch (slideIndex) {
      case 0:
        return locale.helpPackScreenOverviewSlideDescription;
      case 1:
        return locale.helpListScreenEditorSlideDescription;
      case 2:
        return locale.helpPackExportSlideDescription(
            locale.packListScreenBottomNavBarExportActionLabel);
      case 3:
        return locale.helpPackImportSlideDescription(
            locale.packListScreenBottomNavBarImportActionLabel,
            locale.packListScreenBottomNavBarExportActionLabel);
      case 4:
        return locale.helpPackScreenRemovingSlideDescription(
            locale.constsRemovingItemButtonLabel,
            locale.listScreenBottomSnackBarUndoingActionLabel);
      case 5:
        return locale.helpPackScreenCardRelocationSlideDescription(
            locale.storedPackNonePackName);
      case 6:
        return locale.helpPackScreenAddingSlideDescription(
            locale.packScreenSavingAndAddingCardsButtonLabel);
      case 7:
        return locale.helpPackScreenAmendingSlideDescription;
      case 8:
        return locale.helpPackScreenSearchSlideDescription;
      default:
        throw _SliderScreen.createSlideDescriptionNotFoundError(slideIndex);
    }
  }
}

class StudyHelpScreen extends _SliderScreen {
  const StudyHelpScreen()
      : super(const [
          'help_study_preparation',
          'help_study_preparation_study_date',
          'help_study_screen',
          'help_study_editor',
          'help_study_settings'
        ], _descriptor);

  @override
  String getTitle(AppLocalizations locale) =>
      locale.helpScreenTitle(locale.mainScreenStudyModeMenuItemLabel);

  static String _descriptor(int slideIndex, AppLocalizations locale) {
    switch (slideIndex) {
      case 0:
        return locale.helpStudyScreenPreparationSlideDescription;
      case 1:
        return locale.helpStudyScreenPreparationStudyDateSlideDescription(locale
            .barScaffoldSettingsPanelStudySectionStudyDateVisibilityOptionLabel);
      case 2:
        return locale.helpStudyScreenOverviewSlideDescription(
            locale.studyScreenNextCardButtonLabel,
            locale.studyScreenLearningCardButtonLabel);
      case 3:
        return locale.helpStudyEditorSlideDescription(
            locale.constsSavingItemButtonLabel);
      case 4:
        return locale.helpStudySettingsSlideDescription(
            _stringifyEnumValues(StudyDirection.values, locale),
            _stringifyEnumValues(CardSide.values, locale));
      default:
        throw _SliderScreen.createSlideDescriptionNotFoundError(slideIndex);
    }
  }

  static String _stringifyEnumValues(
          Iterable<PresentableEnum> values, AppLocalizations locale) =>
      values.map((d) => d.present(locale)).join('/');
}

class MainMenuHelpScreen extends _SliderScreen {
  const MainMenuHelpScreen()
      : super(const [
          'help_main_screen',
          'help_main_lang_pair_filter',
          'help_main_filtered_pack'
        ], _descriptor);

  @override
  String getTitle(AppLocalizations locale) =>
      locale.helpScreenTitle(locale.mainScreenLabel);

  static String _descriptor(int slideIndex, AppLocalizations locale) {
    switch (slideIndex) {
      case 0:
        return locale.helpMainScreenOverviewSlideDescription;
      case 1:
        return locale.helpMainScreenFilteringPacksAndCardsSlideDescription(
            locale.storedPackNonePackName);
      case 2:
        return locale.helpMainScreenFilteredPackSlideDescription;
      default:
        throw _SliderScreen.createSlideDescriptionNotFoundError(slideIndex);
    }
  }
}
