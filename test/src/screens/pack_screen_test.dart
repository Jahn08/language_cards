import 'package:flutter/material.dart' hide Router, NavigationBar;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/dictionary_provider.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/screens/pack_list_screen.dart';
import 'package:language_cards/src/screens/pack_screen.dart';
import 'package:language_cards/src/widgets/navigation_bar.dart';
import '../../mocks/dictionary_provider_mock.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/root_widget_mock.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/widget_assistant.dart';

void main() {
  testWidgets('Renders a form with empty fields for adding a new pack', (tester) async {
    await _pumpScreen(tester);

    final nameField = tester.widget<TextFormField>(find.byType(TextFormField));
    expect(nameField.controller?.value?.text, '');

    final dropdownType = AssuredFinder.typify<DropdownButtonFormField<String>>();
    final langFields =
        tester.widgetList<DropdownButtonFormField<String>>(find.byType(dropdownType));
    expect(langFields.length, 2);
    expect(langFields.every((f) => f.initialValue == null), true);

    final locale = Localizator.defaultLocalization;
    _assureSavingButtons(locale, tester);

    expect(
        find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(locale.packScreenHeadBarAddingPackTitle)),
        findsOneWidget);
  });

  testWidgets('Renders a form with data of an existing pack', (tester) async {
    final storage = new PackStorageMock();
    final packToEdit = storage.getRandom();
    await _pumpScreen(tester, packId: packToEdit.id, storage: storage);

    expect(find.descendant(of: find.byType(TextFormField), matching: find.text(packToEdit.name)),
        findsOneWidget);

    final dropdownType = AssuredFinder.typify<DropdownButtonFormField<String>>();
    final langFields =
        tester.widgetList<DropdownButtonFormField<String>>(find.byType(dropdownType));
    expect(langFields.length, 2);

    final locale = Localizator.defaultLocalization;
    expect(langFields.first.initialValue, packToEdit.from.present(locale));
    expect(langFields.last.initialValue, packToEdit.to.present(locale));

    _assureSavingButtons(locale, tester, areDisabled: true);

    expect(
        find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(locale.packScreenHeadBarChangingPackTitle)),
        findsOneWidget);
  });

  testWidgets('Warns when choosing a language pair without an available dictionary',
      (tester) async {
    await _testNonAvailableDictionaryWarning(tester,
        shouldWarn: true, fromLang: Language.german, toLang: Language.spanish);
  });

  testWidgets('Does not warn when choosing a language pair with an available dictionary',
      (tester) async {
    await _testNonAvailableDictionaryWarning(tester,
        shouldWarn: false, fromLang: Language.english, toLang: Language.spanish);
  });

  testWidgets('Warns about empty fields and adds no pack', (tester) async {
    final storage = await _pumpScreen(tester);
    final initialPackNumber = (await _fetchPacks(tester, storage)).length;

    final locale = Localizator.defaultLocalization;
    await new WidgetAssistant(tester).tapWidget(_findSavingBtn());

    expect(find.text(locale.constsEmptyValueValidationError), findsNWidgets(3));
    expect((await _fetchPacks(tester, storage)).length, initialPackNumber);
  });

  testWidgets('Warns about equality of chosen languages and adds no pack', (tester) async {
    final storage = await _pumpScreen(tester);
    final initialPackNumber = (await _fetchPacks(tester, storage)).length;

    final assistant = new WidgetAssistant(tester);

    final langToChoose = Randomiser.nextElement(Language.values);
    final langDropdownFinders = _findLanguageDropdowns();
    await assistant.setDropdownItem(langDropdownFinders.first, langToChoose);
    await assistant.setDropdownItem(langDropdownFinders.last, langToChoose);

    await assistant.tapWidget(_findSavingBtn());

    final locale = Localizator.defaultLocalization;
    expect(find.text(locale.packScreenSameTranslationDirectionsValidationError), findsNWidgets(2));
    expect((await _fetchPacks(tester, storage)).length, initialPackNumber);
  });

  testWidgets('Warns about empty fields and makes no changes to an existing pack', (tester) async {
    final storage = new PackStorageMock();
    final packToEdit = storage.getRandom();

    await _pumpScreen(tester, packId: packToEdit.id, storage: storage);

    final assistant = new WidgetAssistant(tester);
    await assistant.enterChangedText(packToEdit.name, changedText: '');

    await assistant.tapWidget(_findLanguageDropdowns().first);
    await assistant.tapWidget(find.byType(TextFormField));

    await assistant.tapWidget(_findSavingBtn());

    expect(
        find.text(Localizator.defaultLocalization.constsEmptyValueValidationError), findsOneWidget);

    final actualPack = await _findPack(tester, storage, packToEdit.id);
    expect(
        actualPack.name == packToEdit.name &&
            actualPack.from == packToEdit.from &&
            actualPack.to == packToEdit.to,
        true);
  });

  testWidgets('Warns about equality of chosen languages and makes no changes to an existing pack',
      (tester) async {
    final storage = new PackStorageMock();
    final packToEdit = storage.getRandom();

    await _pumpScreen(tester, packId: packToEdit.id, storage: storage);

    final assistant = new WidgetAssistant(tester);

    if (packToEdit.from != packToEdit.to)
      await assistant.setDropdownItem(_findLanguageDropdowns().first, packToEdit.to);

    await assistant.tapWidget(_findSavingBtn());

    final locale = Localizator.defaultLocalization;
    expect(find.text(locale.packScreenSameTranslationDirectionsValidationError), findsNWidgets(2));

    final actualPack = await _findPack(tester, storage, packToEdit.id);
    expect(
        actualPack.name == packToEdit.name &&
            actualPack.from == packToEdit.from &&
            actualPack.to == packToEdit.to,
        true);
  });

  testWidgets('Adds a new pack and returns back to the pack list screen', (tester) async {
    await _testAddingPack(tester, shouldAdd: true, saveBtnSearcher: _findSavingBtn);

    AssuredFinder.findOne(
        label: Localizator.defaultLocalization.packListScreenTitle, shouldFind: true);
  });

  testWidgets('Adds a new pack and goes inside it to add cards', (tester) async {
    final addedPack =
        await _testAddingPack(tester, shouldAdd: true, saveBtnSearcher: _findSavingAndAddingBtn);
    _assureBeingInsidePack(addedPack.name);
  });

  testWidgets('Does not add a pack when returning back without saving',
      (tester) => _testAddingPack(tester, shouldAdd: false, saveBtnSearcher: _findBackButton));

  testWidgets('Saves all changes to an existing pack and returns back to the pack list screen',
      (tester) async {
    await _testChangingPack(tester, shouldSave: true, savingBtnSearcher: _findSavingBtn);

    AssuredFinder.findOne(
        label: Localizator.defaultLocalization.packListScreenTitle, shouldFind: true);
  });

  testWidgets('Saves all changes to an existing pack and goes inside it to add cards',
      (tester) async {
    final savedPack = await _testChangingPack(tester,
        shouldSave: true, savingBtnSearcher: _findSavingAndAddingBtn);
    _assureBeingInsidePack(savedPack.name);
  });

  testWidgets('Cancels changes to an existing pack when returning back without saving',
      (tester) => _testChangingPack(tester, shouldSave: false, savingBtnSearcher: _findBackButton));

  testWidgets(
      'Navigates inside a new pack and returns back without a possibility to add the pack twice',
      (tester) async {
    final storage = new PackStorageMock();

    await _testAddingPack(tester,
        shouldAdd: true, storage: storage, saveBtnSearcher: _findSavingAndAddingBtn);

    final expectedPacksNumber = (await _fetchPacks(tester, storage)).length;

    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(_findBackButton());

    await assistant.tapWidget(_findSavingBtn());

    final storedPacks = await _fetchPacks(tester, storage);
    expect(storedPacks.length, expectedPacksNumber);
  });

  testWidgets('Navigates inside a new pack and returns back to the pack list displaying the pack',
      (tester) async {
    final storage = new PackStorageMock();

    final addedPack = await _testAddingPack(tester,
        shouldAdd: true, storage: storage, saveBtnSearcher: _findSavingAndAddingBtn);

    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(_findBackButton());
    await assistant.tapWidget(_findBackButton());

    AssuredFinder.findOne(type: ListTile, label: addedPack.name, shouldFind: true);
  });
}

Future<PackStorageMock> _pumpScreen(WidgetTester tester,
    {DictionaryProvider provider, int packId, PackStorageMock storage}) async {
  storage ??= new PackStorageMock();
  await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
      child: new PackScreen(storage, provider ?? new DictionaryProviderMock(), packId: packId)));

  await new WidgetAssistant(tester).pumpAndAnimate();
  return storage;
}

void _assureSavingButtons(AppLocalizations locale, WidgetTester tester, {bool areDisabled}) {
  [
    locale.packScreenSavingAndAddingCardsButtonLabel,
    locale.constsSavingItemButtonLabel
  ].forEach((btnLbl) => expect(
      tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, btnLbl)).onPressed == null,
      areDisabled ?? false));
}

Future<void> _testNonAvailableDictionaryWarning(WidgetTester tester,
    {bool shouldWarn, Language fromLang, Language toLang}) async {
  await _pumpScreen(tester);

  final langFields = _findLanguageDropdowns();

  final assistant = new WidgetAssistant(tester);
  await assistant.setDropdownItem(langFields.first, fromLang);
  await assistant.setDropdownItem(langFields.last, toLang);

  AssuredFinder.findOne(
      label: Localizator.defaultLocalization.noTranslationSnackBarInfo,
      shouldFind: shouldWarn ?? false);
}

Finder _findLanguageDropdowns() {
  final dropdownType = AssuredFinder.typify<DropdownButton<String>>();
  return AssuredFinder.findSeveral(type: dropdownType, shouldFind: true);
}

Future<List<StoredPack>> _fetchPacks(WidgetTester tester, PackStorageMock storage) =>
    tester.runAsync(() => storage.fetch());

Future<StoredPack> _findPack(WidgetTester tester, PackStorageMock storage, int id) =>
    tester.runAsync(() => storage.find(id));

Future<PackStorageMock> _pumpScreenWithRouting(WidgetTester tester,
    {PackStorageMock storage, String packName}) async {
  storage ??= new PackStorageMock();
  await tester.pumpWidget(RootWidgetMock.buildAsAppHomeWithRouting(
      storage: storage,
      noBar: true,
      packListScreenBuilder: () => new PackListScreen(storage, storage.wordStorage)));

  await tester.pump(const Duration(milliseconds: 500));

  final finder = find.byIcon(Icons.library_books);
  await new WidgetAssistant(tester).tapWidget(finder);

  final assistant = new WidgetAssistant(tester);
  await assistant.tapWidget(packName == null
      ? AssuredFinder.findOne(icon: Icons.add_circle, shouldFind: true)
      : AssuredFinder.findOne(type: ListTile, label: packName, shouldFind: true));

  return storage;
}

Finder _findSavingAndAddingBtn() =>
    _findElevatedBtn(Localizator.defaultLocalization.packScreenSavingAndAddingCardsButtonLabel);

Finder _findElevatedBtn(String btnLabel) =>
    AssuredFinder.findOne(label: btnLabel, type: ElevatedButton, shouldFind: true);

Finder _findSavingBtn() =>
    _findElevatedBtn(Localizator.defaultLocalization.constsSavingItemButtonLabel);

Future<StoredPack> _testAddingPack(WidgetTester tester,
    {@required Finder Function() saveBtnSearcher,
    @required bool shouldAdd,
    PackStorageMock storage}) async {
  final packStorage = await _pumpScreenWithRouting(tester, storage: storage);
  final initialPackNumber = (await _fetchPacks(tester, packStorage)).length;

  final assistant = new WidgetAssistant(tester);

  final langDropdownFinders = _findLanguageDropdowns();

  const fromLang = Language.english;
  await assistant.setDropdownItem(langDropdownFinders.first, fromLang);

  const toLang = Language.german;
  await assistant.setDropdownItem(langDropdownFinders.last, toLang);

  final packName = Randomiser.nextString();
  await assistant.enterText(find.byType(TextFormField), packName);

  await assistant.tapWidget(saveBtnSearcher());

  final actualPacks = await _fetchPacks(tester, packStorage);
  expect(actualPacks.length, initialPackNumber + (shouldAdd ? 1 : 0));

  final storedPack = actualPacks.singleWhere((p) => p.name == packName, orElse: () => null);
  if (shouldAdd) {
    expect(storedPack.from, fromLang);
    expect(storedPack.to, toLang);
  } else
    expect(storedPack, null);

  return storedPack;
}

void _assureBeingInsidePack(String packName) => expect(
    find.descendant(of: find.byType(NavigationBar), matching: find.text(packName)), findsOneWidget);

Future<StoredPack> _testChangingPack(WidgetTester tester,
    {@required Finder Function() savingBtnSearcher, @required bool shouldSave}) async {
  final storage = new PackStorageMock();
  final packToEdit = storage.getRandom();

  await _pumpScreenWithRouting(tester, storage: storage, packName: packToEdit.name);

  final assistant = new WidgetAssistant(tester);
  final newName = await assistant.enterChangedText(packToEdit.name);

  final langDropdownFinders = _findLanguageDropdowns();
  final newFromLang =
      Language.values.firstWhere((lg) => lg != packToEdit.from && lg != packToEdit.to);
  await assistant.setDropdownItem(langDropdownFinders.first, newFromLang);

  final newToLang = Language.values.firstWhere((lg) => lg != newFromLang && lg != packToEdit.to);
  await assistant.setDropdownItem(langDropdownFinders.last, newToLang);

  await assistant.tapWidget(savingBtnSearcher());

  final actualPack = await _findPack(tester, storage, packToEdit.id);

  if (shouldSave) {
    expect(actualPack.name, newName);
    expect(actualPack.from, newFromLang);
    expect(actualPack.to, newToLang);
  } else {
    expect(actualPack.name, packToEdit.name);
    expect(actualPack.from, packToEdit.from);
    expect(actualPack.to, packToEdit.to);
  }

  return actualPack;
}

Finder _findBackButton() => AssuredFinder.findOne(type: BackButton, shouldFind: true);
