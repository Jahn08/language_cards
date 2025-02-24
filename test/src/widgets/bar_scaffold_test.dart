import 'package:flutter/material.dart' hide NavigationBar;
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/app.dart';
import 'package:language_cards/src/blocs/settings_bloc.dart';
import 'package:language_cards/src/data/preferences_provider.dart';
import 'package:language_cards/src/models/presentable_enum.dart';
import 'package:language_cards/src/models/user_params.dart';
import 'package:language_cards/src/widgets/asset_icon.dart';
import 'package:language_cards/src/widgets/bar_scaffold.dart';
import 'package:language_cards/src/widgets/icon_option.dart';
import 'package:language_cards/src/widgets/navigation_bar.dart';
import 'package:language_cards/src/widgets/styled_dropdown.dart';
import '../../mocks/root_widget_mock.dart';
import '../../testers/preferences_tester.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';
import '../../utilities/widget_assistant.dart';

void main() {
  testWidgets(
      'Renders a scaffold with passed widgets and title for a non-navigational bar',
      (tester) async {
    final expectedTitle = Randomiser.nextString();
    final expectedBodyText = Randomiser.nextString();

    final expectedBarActionText = Randomiser.nextString();
    final expectedBarAction = _buildBarAction(expectedBarActionText);

    final bottomNavBarFirstItemTitle = Randomiser.nextString();
    final bottomNavBarSecondItemTitle = Randomiser.nextString();

    final bottomNavBarKey = new Key(Randomiser.nextString());
    final floatingActionBtnKey = new Key(Randomiser.nextString());

    const navBarItemIcon = Icon(Icons.ac_unit);

    await _buildInsideApp(
        tester,
        new BarScaffold(
            title: expectedTitle,
            bottomBar: new BottomNavigationBar(
                key: bottomNavBarKey,
                items: <BottomNavigationBarItem>[
                  new BottomNavigationBarItem(
                      icon: navBarItemIcon, label: bottomNavBarFirstItemTitle),
                  new BottomNavigationBarItem(
                      icon: navBarItemIcon, label: bottomNavBarSecondItemTitle)
                ]),
            body: new Text(expectedBodyText),
            barActions: <Widget>[expectedBarAction],
            floatingActionButton: new FloatingActionButton(
                key: floatingActionBtnKey, onPressed: null)));

    AssuredFinder.findOne(label: expectedTitle, shouldFind: true);
    AssuredFinder.findOne(label: expectedBodyText, shouldFind: true);

    AssuredFinder.findOne(type: NavigationBar, shouldFind: false);
    AssuredFinder.findOne(label: expectedBarActionText, shouldFind: true);

    AssuredFinder.findOne(key: bottomNavBarKey, shouldFind: true);
    AssuredFinder.findOne(label: bottomNavBarFirstItemTitle, shouldFind: true);
    AssuredFinder.findOne(label: bottomNavBarSecondItemTitle, shouldFind: true);

    AssuredFinder.findOne(key: expectedBarAction.key, shouldFind: true);
    AssuredFinder.findOne(key: floatingActionBtnKey, shouldFind: true);
  });

  testWidgets(
      'Renders a navigational bar with actions when a navigation callback is provided',
      (tester) async {
    final expectedBarActionText = Randomiser.nextString();
    final expectedBarAction = _buildBarAction(expectedBarActionText);

    await _buildInsideApp(
        tester,
        new BarScaffold(
            title: Randomiser.nextString(),
            body: new Text(Randomiser.nextString()),
            onNavGoingBack: () {},
            barActions: <Widget>[expectedBarAction]));

    AssuredFinder.findOne(
        label: expectedBarActionText, type: NavigationBar, shouldFind: true);
    AssuredFinder.findOne(key: expectedBarAction.key, shouldFind: true);
  });

  testWidgets('Renders no button to open the settings panel by default',
      (tester) async {
    await _buildInsideApp(
        tester,
        new BarScaffold(
            title: Randomiser.nextString(),
            body: new Text(Randomiser.nextString())));

    _assureSettingsBtn(false);
  });

  testWidgets('Renders the settings panel with user preferences',
      (tester) async {
    final userParams = await PreferencesTester.saveRandomUserParams();

    final expectedLang = userParams.interfaceLang;
    final expectedTheme = userParams.theme;

    await _pumpScaffoldWithSettings(tester);

    final settingsBtnFinder = _assureSettingsBtn(true);
    await new WidgetAssistant(tester).tapWidget(settingsBtnFinder);

    final iconOptionsFinder =
        AssuredFinder.findSeveral(type: IconOption, shouldFind: true);
    expect(tester.widgetList(iconOptionsFinder).length,
        UserParams.interfaceLanguages.length + AppTheme.values.length);

    Finder getLangOptionFinder({bool isSelected = false}) => find.descendant(
        of: find.byWidgetPredicate(
            (w) => w is IconOption && w.isSelected == isSelected),
        matching: find.byType(AssetIcon));

    UserParams.interfaceLanguages.forEach((lang) {
      expect(
          tester.widget<AssetIcon>(
              getLangOptionFinder(isSelected: expectedLang == lang)),
          AssetIcon.getByLanguage(lang));
    });

    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(getLangOptionFinder());

    final chosenLang = UserParams.interfaceLanguages
        .firstWhere((lang) => lang != expectedLang);
    expect(tester.widget<AssetIcon>(getLangOptionFinder(isSelected: true)),
        AssetIcon.getByLanguage(chosenLang));

    Color getThemeColour(AppTheme theme) =>
        Colors.blueGrey[theme == AppTheme.dark ? 900 : 100]!;

    Finder getThemeOptionFinder({bool isSelected = false}) => find.descendant(
        of: find.byWidgetPredicate(
            (w) => w is IconOption && w.isSelected == isSelected),
        matching:
            find.byWidgetPredicate((w) => w is Container && w.child == null));

    AppTheme.values.forEach((theme) {
      expect(
          tester
              .widget<Container>(
                  getThemeOptionFinder(isSelected: expectedTheme == theme))
              .color,
          getThemeColour(theme));
    });

    await assistant.tapWidget(getThemeOptionFinder());

    final chosenTheme =
        AppTheme.values.firstWhere((theme) => theme != expectedTheme);
    expect(
        tester.widget<Container>(getThemeOptionFinder(isSelected: true)).color,
        getThemeColour(chosenTheme));

    const expectedDropdownNumber = 3;
    final dropdowns = tester.widgetList<StyledDropdown>(
        AssuredFinder.findSeveral(type: StyledDropdown, shouldFind: true));
    expect(dropdowns.length, expectedDropdownNumber);

    final locale = Localizator.defaultLocalization;
    final packOrders =
        PresentableEnum.mapStringValues(PackOrder.values, locale).keys.toSet();
    dropdowns
        .singleWhere((d) => d.options.every((op) => packOrders.contains(op)));

    final cardSides =
        PresentableEnum.mapStringValues(CardSide.values, locale).keys.toSet();
    dropdowns
        .singleWhere((d) => d.options.every((op) => cardSides.contains(op)));

    final studyDirections =
        PresentableEnum.mapStringValues(StudyDirection.values, locale)
            .keys
            .toSet();
    dropdowns.singleWhere(
        (d) => d.options.every((op) => studyDirections.contains(op)));

    final dropDownBtnType = AssuredFinder.typify<DropdownButton<String>>();
    final dropdownBtnValues = tester
        .widgetList<DropdownButton<String>>(
            AssuredFinder.findSeveral(type: dropDownBtnType, shouldFind: true))
        .map((e) => e.value)
        .toList();
    expect(dropdownBtnValues.length, expectedDropdownNumber);

    final studyParams = userParams.studyParams;
    final dropdownBtnValuesSet = dropdownBtnValues.toSet();
    [
      studyParams.cardSide.present(locale),
      studyParams.direction.present(locale),
      studyParams.packOrder.present(locale)
    ].every((p) => dropdownBtnValuesSet.contains(p));

    final studyDateCheckFinder =
        AssuredFinder.findOne(type: CheckboxListTile, shouldFind: true);
    expect(tester.widget<CheckboxListTile>(studyDateCheckFinder).value,
        studyParams.showStudyDate);
  });
  
  testWidgets('Navigates between sections of the settings panel',
      (tester) async {
    await PreferencesTester.saveRandomUserParams();
    
    await _pumpScaffoldWithSettings(tester);
    
    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(_assureSettingsBtn(true));

    final panelFinder = AssuredFinder.findOne(type: ExpansionPanelList, shouldFind: true);
    var sections = tester.widget<ExpansionPanelList>(panelFinder).children;
    expect(sections.where((p) => p.isExpanded).length, 1);
    expect(sections[0].isExpanded, true);
    
    final settingsSectionHeaderFinder = find.descendant(of: panelFinder, matching: find.byType(SettingsSectionHeader));
    await assistant.tapWidget(settingsSectionHeaderFinder);
    sections = tester.widget<ExpansionPanelList>(panelFinder).children;
    expect(sections.every((p) => !p.isExpanded), true);

    final contactsSectionHeaderFinder = find.descendant(of: panelFinder, matching: find.byType(ContactsSectionHeader));
    await assistant.tapWidget(contactsSectionHeaderFinder);
    sections = tester.widget<ExpansionPanelList>(panelFinder).children;
    expect(sections.where((p) => p.isExpanded).length, 1);
    expect(sections[1].isExpanded, true);

    final helpSectionHeaderFinder = find.descendant(of: panelFinder, matching: find.byType(HelpSectionHeader));
    await assistant.tapWidget(helpSectionHeaderFinder);
    sections = tester.widget<ExpansionPanelList>(panelFinder).children;
    expect(sections.where((p) => p.isExpanded).length, 1);
    expect(sections[2].isExpanded, true);
  });

  testWidgets(
      'Saves and hides settings after clicking the apply button on the panel',
      (tester) async {
    await PreferencesTester.saveDefaultUserParams();
    final defaultUserParams = await PreferencesProvider.fetch();

    await _pumpScaffoldWithSettings(tester);

    final settingsBtnFinder = _assureSettingsBtn(true);
    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(settingsBtnFinder);

    final iconOptionsFinder =
        AssuredFinder.findSeveral(type: IconOption, shouldFind: true);

    final nonChosenOptionsFinder = find.descendant(
        of: iconOptionsFinder,
        matchRoot: true,
        matching:
            find.byWidgetPredicate((w) => w is IconOption && !w.isSelected));
    expect(nonChosenOptionsFinder, findsWidgets);

    await assistant.tapWidget(nonChosenOptionsFinder.first, atCenter: true);
    await assistant.tapWidget(nonChosenOptionsFinder.last, atCenter: true);

    final defStudyParams = defaultUserParams.studyParams;
    const expectedPackOrder = PackOrder.byDateAsc;
    await assistant.changeDropdownItem(
        defStudyParams.packOrder, expectedPackOrder);

    const expectedCardSide = CardSide.back;
    await assistant.changeDropdownItem(
        defStudyParams.cardSide, expectedCardSide);

    const expectedDirection = StudyDirection.random;
    await assistant.changeDropdownItem(
        defStudyParams.direction, expectedDirection);

    final studyDateCheckFinder =
        AssuredFinder.findOne(type: CheckboxListTile, shouldFind: true);
    await assistant.tapWidget(studyDateCheckFinder);

    await _applySettings(assistant);

    final savedUserParams = await PreferencesProvider.fetch();
    expect(savedUserParams.theme == defaultUserParams.theme, false);
    expect(savedUserParams.interfaceLang == defaultUserParams.interfaceLang,
        false);

    final studyParams = savedUserParams.studyParams;
    expect(studyParams.packOrder == defStudyParams.packOrder, false);
    expect(studyParams.packOrder, expectedPackOrder);

    expect(studyParams.cardSide == defStudyParams.cardSide, false);
    expect(studyParams.cardSide, expectedCardSide);

    expect(studyParams.direction == defStudyParams.direction, false);
    expect(studyParams.direction, expectedDirection);

    expect(studyParams.showStudyDate == defStudyParams.showStudyDate, false);
    expect(studyParams.showStudyDate, false);
  });

  testWidgets('Resets settings after clicking the reset button on the panel',
      (tester) async {
    final userParams = await PreferencesTester.saveNonDefaultUserParams();
    final defaultUserParams = new UserParams();
    expect(userParams.theme == defaultUserParams.theme, false);
    expect(userParams.interfaceLang == defaultUserParams.interfaceLang, false);

    final defStudyParams = defaultUserParams.studyParams;
    expect(userParams.studyParams.packOrder == defStudyParams.packOrder, false);
    expect(userParams.studyParams.cardSide == defStudyParams.cardSide, false);
    expect(userParams.studyParams.direction == defStudyParams.direction, false);
    expect(userParams.studyParams.showStudyDate == defStudyParams.showStudyDate,
        false);

    await _pumpScaffoldWithSettings(tester);

    final settingsBtnFinder = _assureSettingsBtn(true);
    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(settingsBtnFinder);

    await assistant.pressButtonDirectlyByLabel('Reset');

    await _applySettings(assistant);

    final storedUserParams = await PreferencesProvider.fetch();
    expect(storedUserParams.theme, defaultUserParams.theme);
    expect(storedUserParams.interfaceLang, defaultUserParams.interfaceLang);

    final curStudyParams = storedUserParams.studyParams;
    expect(curStudyParams.cardSide, defStudyParams.cardSide);
    expect(curStudyParams.direction, defStudyParams.direction);
    expect(curStudyParams.showStudyDate, defStudyParams.showStudyDate);
  });

  testWidgets(
      'Changes the interface language immediately after applying the setting',
      (tester) async {
    await PreferencesTester.saveDefaultUserParams();
    await tester.pumpWidget(const App());
    await tester.pump();
    await tester.pump();

    final settingsBtnFinder = _assureSettingsBtn(true);
    final assistant = new WidgetAssistant(tester);
    await assistant.tapWidget(settingsBtnFinder);

    final iconOptionFinder =
        find.byWidgetPredicate((w) => w == AssetIcon.russianFlag);
    expect(iconOptionFinder, findsOneWidget);

    await assistant.tapWidget(iconOptionFinder);

    await _applySettings(assistant);

    await assistant.tapWidget(settingsBtnFinder);

    final allTexts = tester
        .widgetList<Text>(
            AssuredFinder.findSeveral(type: Text, shouldFind: true))
        .toList();
    expect(
        allTexts.where((t) => t.data!.contains(new RegExp('[A-Za-z]'))).length,
        1,
        reason:
            'There are not enough English labels in [${allTexts.join(',')}]');
  });
}

Future<void> _buildInsideApp(WidgetTester tester, Widget child) =>
    tester.pumpWidget(RootWidgetMock.buildAsAppHome(child: child));

TextButton _buildBarAction(String label) => new TextButton(
    key: new Key(Randomiser.nextString()),
    child: new Text(label),
    onPressed: null);

Finder _assureSettingsBtn(bool shouldFind) =>
    AssuredFinder.findOne(icon: Icons.settings, shouldFind: shouldFind);

Future<void> _pumpScaffoldWithSettings(WidgetTester tester) => _buildInsideApp(
    tester,
    new SettingsBlocProvider(
        child: new BarScaffold.withSettings(Randomiser.nextString(),
            body: new Text(Randomiser.nextString()))));

Future<void> _applySettings(WidgetAssistant assistant) async =>
    assistant.pressButtonDirectlyByLabel(Localizator
        .defaultLocalization.barScaffoldSettingsPanelApplyingButtonLabel);
