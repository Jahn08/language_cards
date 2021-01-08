import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/blocs/settings_bloc.dart';
import 'package:language_cards/src/data/preferences_provider.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/user_params.dart';
import 'package:language_cards/src/utilities/enum.dart';
import 'package:language_cards/src/widgets/asset_icon.dart';
import 'package:language_cards/src/widgets/bar_scaffold.dart';
import 'package:language_cards/src/widgets/icon_option.dart';
import 'package:language_cards/src/widgets/navigation_bar.dart';
import 'package:language_cards/src/widgets/styled_dropdown.dart';
import '../testers/preferences_tester.dart';
import '../utilities/assured_finder.dart';
import '../utilities/randomiser.dart';
import '../utilities/widget_assistant.dart';

void main() {

    testWidgets('Renders a scaffold with passed widgets and title for a non-navigational bar',
        (tester) async {
            final expectedTitle = Randomiser.nextString();
            final expectedBodyText = Randomiser.nextString();

            final expectedBarActionText = Randomiser.nextString();
            final expectedBarAction = _buildBarAction(expectedBarActionText);

            final bottomNavBarFirstItemTitle = Randomiser.nextString();
            final bottomNavBarSecondItemTitle = Randomiser.nextString();

            final bottomNavBarKey = new Key(Randomiser.nextString());
            final floatingActionBtnKey = new Key(Randomiser.nextString());
            
            final navBarItemIcon = new Icon(Icons.ac_unit);

            await _buildInsideApp(tester, new BarScaffold(expectedTitle, 
                bottomNavigationBar: new BottomNavigationBar(
                    key: bottomNavBarKey,
                    items: <BottomNavigationBarItem>[
                        new BottomNavigationBarItem(
                            icon: navBarItemIcon,
                            label: bottomNavBarFirstItemTitle
                        ),
                        new BottomNavigationBarItem(
                            icon: navBarItemIcon,
                            label: bottomNavBarSecondItemTitle
                        )
                    ]
                ),
                body: new Text(expectedBodyText),
                barActions: <Widget>[expectedBarAction],
                floatingActionButton: new FloatingActionButton(
                    key: floatingActionBtnKey,
                    onPressed: null
                )
            ));

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

    testWidgets('Renders a navigational bar with actions when a navigation callback is provided', 
        (tester) async {
            final expectedBarActionText = Randomiser.nextString();
            final expectedBarAction = _buildBarAction(expectedBarActionText);

            await _buildInsideApp(tester, new BarScaffold(Randomiser.nextString(), 
                body: new Text(Randomiser.nextString()),
                onNavGoingBack: () {},
                barActions: <Widget>[expectedBarAction]
            ));

            AssuredFinder.findOne(label: expectedBarActionText, type: NavigationBar,
                shouldFind: true);
            AssuredFinder.findOne(key: expectedBarAction.key, shouldFind: true);
        });

    testWidgets('Renders no button to open the settings panel by default', (tester) async {
        await _buildInsideApp(tester, new BarScaffold(Randomiser.nextString(), 
            body: new Text(Randomiser.nextString())));

        _assureSettingsBtn(false);
    });

    testWidgets('Renders the settings panel with user preferences', (tester) async {
        final userParams = await PreferencesTester.saveRandomUserParams();

        final expectedLang = userParams.interfaceLang;
        final expectedTheme = userParams.theme;

        await _pumpScaffoldWithSettings(tester);

        final settingsBtnFinder = _assureSettingsBtn(true);
        await new WidgetAssistant(tester).tapWidget(settingsBtnFinder);

        final iconOptionsFinder = AssuredFinder.findSeveral(type: IconOption, 
            shouldFind: true);
        expect(tester.widgetList(iconOptionsFinder).length, 
            Language.values.length + AppTheme.values.length);

        Language.values.forEach((lang) {
            final optionFinder = find.descendant(of: iconOptionsFinder, matchRoot: true,
                matching: find.byWidgetPredicate(
                    (w) => w is IconOption && w.isSelected == (expectedLang == lang)));
            final iconFinder = find.descendant(of: optionFinder, 
                matching: find.byType(AssetIcon));
            expect(iconFinder, findsOneWidget);
            expect(tester.widget<AssetIcon>(iconFinder), AssetIcon.getByLanguage(lang));
        });

        AppTheme.values.forEach((theme) {
            final optionFinder = find.descendant(of: iconOptionsFinder, matchRoot: true,
                matching: find.byWidgetPredicate(
                    (w) => w is IconOption && w.isSelected == (expectedTheme == theme)));
            final colouredContainerFinder = find.descendant(of: optionFinder, 
                matching: find.byWidgetPredicate((w) => w is Container && w.child == null));
            expect(colouredContainerFinder, findsOneWidget);
            expect(tester.widget<Container>(colouredContainerFinder).color,
                Colors.blueGrey[theme == AppTheme.dark ? 900: 100]);
        });

		final dropdowns = tester.widgetList<StyledDropdown>(
			AssuredFinder.findSeveral(type: StyledDropdown, shouldFind: true));
		expect(dropdowns.length, 2);

		final cardSides = Enum.mapStringValues(CardSide.values).keys;
		dropdowns.singleWhere((d) => d.options.every((op) => cardSides.contains(op)));
		
		final studyDirections = Enum.mapStringValues(StudyDirection.values).keys;
		dropdowns.singleWhere((d) => d.options.every((op) => studyDirections.contains(op)));

		final dropDownBtnType = AssuredFinder.typify<DropdownButton<String>>();
		final dropdownBtns = tester.widgetList<DropdownButton<String>>(
			AssuredFinder.findSeveral(type: dropDownBtnType, shouldFind: true));
		expect(dropdownBtns.length, 2);

		final studyParams = userParams.studyParams;
		[Enum.stringifyValue(studyParams.cardSide), Enum.stringifyValue(studyParams.direction)]
			.every((p) => dropdownBtns.contains((d) => d.value == p));
    });

    testWidgets('Saves and hides settings after clicking the apply button on the panel', 
        (tester) async {
            PreferencesTester.resetSharedPreferences();
            final defaultUserParams = await PreferencesProvider.fetch();

            await _pumpScaffoldWithSettings(tester);

            final settingsBtnFinder = _assureSettingsBtn(true);
            final assistant = new WidgetAssistant(tester);
            await assistant.tapWidget(settingsBtnFinder);

            final iconOptionsFinder = AssuredFinder.findSeveral(type: IconOption, 
                shouldFind: true);

            final nonChosenOptionsFinder = find.descendant(
                of: iconOptionsFinder, matchRoot: true,
                matching: find.byWidgetPredicate((w) => w is IconOption && !w.isSelected));
            expect(nonChosenOptionsFinder, findsWidgets);
            
            await assistant.tapWidget(nonChosenOptionsFinder.first);
            await assistant.tapWidget(nonChosenOptionsFinder.last);

			final defStudyParams = defaultUserParams.studyParams;
			final expectedCardSide = CardSide.back;
			await _chooseDropdownItem<CardSide>(tester, defStudyParams.cardSide, expectedCardSide);
			
			final expectedDirection = StudyDirection.random;
			await _chooseDropdownItem<StudyDirection>(tester, defStudyParams.direction, 
				expectedDirection);

            await _applySettings(assistant);

            final savedUserParams = await PreferencesProvider.fetch();
            expect(savedUserParams.theme == defaultUserParams.theme, false);
            expect(savedUserParams.interfaceLang == defaultUserParams.interfaceLang, false);
            
			final studyParams = savedUserParams.studyParams;
			expect(studyParams.cardSide == defStudyParams.cardSide, false);
			expect(studyParams.cardSide, expectedCardSide);

			expect(studyParams.direction == defStudyParams.direction, false);
			expect(studyParams.direction, expectedDirection);
        });

    testWidgets('Resets settings after clicking the reset button on the panel', (tester) async {
        final userParams = await PreferencesTester.saveNonDefaultUserParams();
        final defaultUserParams = new UserParams();
        expect(userParams.theme == defaultUserParams.theme, false);
        expect(userParams.interfaceLang == defaultUserParams.interfaceLang, false);

		final defStudyParams = defaultUserParams.studyParams;
	    expect(userParams.studyParams.cardSide == defStudyParams.cardSide, false);
		expect(userParams.studyParams.direction == defStudyParams.direction, false);

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
    });
}

Future<void> _buildInsideApp(WidgetTester tester, Widget child) async => 
    await tester.pumpWidget(new MaterialApp(home: child));

FlatButton _buildBarAction(String label) => new FlatButton(
    key: new Key(Randomiser.nextString()),
    child: new Text(label),
    onPressed: null
);

Finder _assureSettingsBtn(bool shouldFind) =>
    AssuredFinder.findOne(icon: Icons.settings, shouldFind: shouldFind);

Future<void> _pumpScaffoldWithSettings(WidgetTester tester) async => 
    await _buildInsideApp(tester, new SettingsBlocProvider(
        child: new BarScaffold(Randomiser.nextString(), 
            body: new Text(Randomiser.nextString()),
            showSettings: true
        )
    ));

Future<void> _applySettings(WidgetAssistant assistant) async => 
    await assistant.pressButtonDirectlyByLabel('Apply');

Future<void> _chooseDropdownItem<T>(WidgetTester tester, T curValue, T valueToChoose) async {
	final dropDownBtnType = AssuredFinder.typify<DropdownButton<String>>();
	final cardSideDropdownFinder = find.widgetWithText(dropDownBtnType, 
		Enum.stringifyValue(curValue));
	
	final widgetAssistant = new WidgetAssistant(tester);
	await widgetAssistant.tapWidget(cardSideDropdownFinder);
	
	await widgetAssistant.tapWidget(
		find.text(Enum.stringifyValue(valueToChoose)).hitTestable());
}
