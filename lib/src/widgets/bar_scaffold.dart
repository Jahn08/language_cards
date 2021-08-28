import 'package:flutter/material.dart' hide Router;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'asset_icon.dart';
import 'icon_option.dart';
import '../consts.dart';
import '../router.dart';
import '../blocs/settings_bloc.dart';
import '../data/configuration.dart';
import '../models/language.dart';
import '../models/presentable_enum.dart';
import '../models/user_params.dart';
import '../utilities/link.dart';
import '../utilities/string_ext.dart';
import '../widgets/loader.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/one_line_text.dart';
import '../widgets/styled_dropdown.dart';

class _SettingsPanelState extends State<_SettingsPanel> {

	int _expandedPanelIndex = 0;

    @override
    Widget build(BuildContext context) =>
		new Drawer(
			child: new SingleChildScrollView(
				child: new Column(
					children: [
						new Padding(
							child: new ExpansionPanelList(
								children: [
									_buildPanel(0, 
										header: const _SettingsSectionHeader(),
										body: const _SettingsSectionBody()
									),
									_buildPanel(1, 
										header: const _ContactsSectionHeader(),
										body: const _ContactsSectionBody()
									),
									_buildPanel(2,
										header: const _HelpSectionHeader(),
										body: const _HelpSectionBody()
									)
								],
								expansionCallback: (panelIndex, isExpanded) {
									setState(() => _expandedPanelIndex = isExpanded ? null: panelIndex);	
								}
							),
							padding: const EdgeInsets.only(top: 30)
						)
					]
				)
			)  
		);

	ExpansionPanel _buildPanel(int index, { Widget header, Widget body }) => 
		new ExpansionPanel(
			headerBuilder: (context, _) => header,
			body: body,
			canTapOnHeader: true,
			isExpanded: _expandedPanelIndex == index
		);
}

class _SettingsSectionBodyState extends State<_SettingsSectionBody> {
	
    UserParams _params;

    String _originalParams;

	final _langParamNotifier = new ValueNotifier<Language>(null);
	final _themeParamNotifier = new ValueNotifier<AppTheme>(null);
	
	final _cardSideParamNotifier = new ValueNotifier<CardSide>(null);
	final _directionParamNotifier = new ValueNotifier<StudyDirection>(null);

	final _isStateDirtyNotifier = new ValueNotifier<bool>(false);

	@override
	void dispose() {
		_langParamNotifier.dispose();
		_themeParamNotifier.dispose();

		_cardSideParamNotifier.dispose();
		_directionParamNotifier.dispose();

		_isStateDirtyNotifier.dispose();

		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
        final bloc = SettingsBlocProvider.of(context);
        
		return new FutureLoader<UserParams>(bloc.userParams, (params) {
			if (_params == null) {
				_setParams(params, locale);
				_originalParams = _params.toJson();
			}

			final directionDic = PresentableEnum.mapStringValues(StudyDirection.values, locale);
			final sideDic = PresentableEnum.mapStringValues(CardSide.values, locale);
			
			return new Column(children: [
				const _LanguageSubSectionHeader(),
				new ValueListenableBuilder(
					valueListenable: _langParamNotifier,
					builder: (_, Language interfaceLang, __) => 
						new _LanguageSettingsSection(interfaceLang, 
							(newLang) {
								_params.interfaceLang = newLang;
								_langParamNotifier.value = newLang;

								_setDirtinessState();
							})
				),
				const _AppearanceSubSectionHeader(),
				new ValueListenableBuilder(
					valueListenable: _themeParamNotifier,
					builder: (_, AppTheme theme, __) => 
						new _AppearanceSettingsSection(theme, 
							(newTheme) {
								_params.theme = newTheme;
								_themeParamNotifier.value = newTheme;

								_setDirtinessState();
							})
				),
				const _SettingsSubSectionHeader(),
				new ValueListenableBuilder(
					valueListenable: _directionParamNotifier,
					builder: (_, StudyDirection direction, __) =>
						new _StudySettingsSectionRow(
							options: directionDic.keys,
							inintialValue: direction.present(locale),
							label: locale.barScaffoldSettingsPanelStudySectionSortingCardOptionLabel,
							onValueChanged: (newValue) {
								final newDirection = directionDic[newValue];
								_params.studyParams.direction = newDirection;
								_directionParamNotifier.value = newDirection;
							
								_setDirtinessState();
							}
						)
				),
				new ValueListenableBuilder(
					valueListenable: _cardSideParamNotifier,
					builder: (_, CardSide cardSide, __) => 
						new _StudySettingsSectionRow(
							options: sideDic.keys,
							inintialValue: cardSide.present(locale),
							label: locale.barScaffoldSettingsPanelStudySectionCardSideOptionLabel,
							onValueChanged: (newValue) {
								final newCardSide = sideDic[newValue];
								_params.studyParams.cardSide = newCardSide;
								_cardSideParamNotifier.value = newCardSide;
							
								_setDirtinessState();
							}
						)
				),
				new Row(
					mainAxisAlignment: MainAxisAlignment.spaceEvenly,
					children: [
						new ElevatedButton(
							child: new Text(locale.barScaffoldSettingsPanelResettingButtonLabel),
							onPressed: () {
								_setParams(new UserParams(), locale);
								_setDirtinessState();
							}
						),
						new ValueListenableBuilder(
							valueListenable: _isStateDirtyNotifier,
							child: new Text(locale.barScaffoldSettingsPanelApplyingButtonLabel),
							builder: (_, bool isDirty, label) => 
								new ElevatedButton(
									child: label,
									onPressed: isDirty ? () async {
										await bloc.save(_params);
										
										if (!mounted)
											return;
										
										Navigator.pop(context);
									}: null
								)
						)
					]
				)
			]);
		});
	}

	void _setParams(UserParams newParams, AppLocalizations locale) {
		_params = newParams;

		_langParamNotifier.value = _params.interfaceLang;
		_themeParamNotifier.value = _params.theme;

		_cardSideParamNotifier.value = _params.studyParams.cardSide;
		_directionParamNotifier.value = _params.studyParams.direction;
	}

	void _setDirtinessState() => _isStateDirtyNotifier.value = _originalParams != _params.toJson();
}

class _SettingsSectionBody extends StatefulWidget {
	
	const _SettingsSectionBody();

	@override
	State<StatefulWidget> createState() => new _SettingsSectionBodyState();
}

class _StudySettingsSectionRow extends StatelessWidget {

	final Iterable<String> options;

	final String inintialValue;

	final String label;

	final void Function(String) onValueChanged;

	const _StudySettingsSectionRow({ this.options, this.inintialValue, this.onValueChanged, this.label });

	@override
	Widget build(BuildContext context) => 
		new Row(children: <Widget>[
				new Expanded(
					child: new Container(
						child: new StyledDropdown(options, 
							label: label,
							initialValue: inintialValue,
							onChanged: onValueChanged
						),
						margin: const EdgeInsets.only(bottom: 5, top: 10)
					)
            	)
        ]);	
}

class _AppearanceSettingsSection extends StatelessWidget {
	
	final AppTheme theme;

	final void Function(AppTheme) onThemeChanged;

	const _AppearanceSettingsSection(this.theme, this.onThemeChanged);

	@override
	Widget build(BuildContext context) =>
		new Row(children: AppTheme.values.map((t) => 
			new _AppearanceOption(
				theme: t, 
				isSelected: t == theme,
				onTap: () => onThemeChanged(t)
			)).toList());
}

class _AppearanceOption extends StatelessWidget {
	
	final AppTheme theme;

	final bool isSelected;
	
	final void Function() onTap;

	const _AppearanceOption({ this.theme, this.isSelected, this.onTap });

	@override
	Widget build(BuildContext context) =>
    	new GestureDetector(
            child: new IconOption(
                icon: new Container(
                    height: AssetIcon.heightValue,
                    width: AssetIcon.widthValue,
                    color: Colors.blueGrey[theme == AppTheme.dark ? 900: 100]
                ), 
                isSelected: isSelected
            ),
            onTap: () {
                if (isSelected)
                    return;

				onTap();
            }
        );
}

class _LanguageSettingsSection extends StatelessWidget {
	
	final Language interfaceLang;

	final void Function(Language) onLangChanged;

	const _LanguageSettingsSection(this.interfaceLang, this.onLangChanged);

	@override
	Widget build(BuildContext context) =>
		new Row(children: UserParams.interfaceLanguages
			.map((ln) => new _LanguageOption(
				lang: ln, 
				isSelected: ln == interfaceLang,
				onTap: () => onLangChanged(ln)
			)).toList());
}

class _LanguageOption extends StatelessWidget {
	
	final Language lang;

	final bool isSelected;
	
	final void Function() onTap;

	const _LanguageOption({ this.lang, this.isSelected, this.onTap });

	@override
	Widget build(BuildContext context) =>
		new GestureDetector(
            child: new IconOption(
                icon: AssetIcon.getByLanguage(lang), 
                isSelected: isSelected
            ),
            onTap: () {
                if (isSelected)
                    return;

				onTap();
            }
        );
}

class _HelpSectionBody extends StatelessWidget {

	const _HelpSectionBody();

	@override
	Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
		return new Column(
			children: [
				new _TextButtonedRow(locale.mainScreenStudyModeMenuItemLabel, 
					() => Router.goToStudyHelp(context)),
				new _TextButtonedRow(locale.mainScreenWordPacksMenuItemLabel, 
					() => Router.goToPackHelp(context)),
				new _TextButtonedRow(locale.mainScreenWordCardsMenuItemLabel, 
					() => Router.goToCardHelp(context))
			]
		);
	}
}

class _ContactsSectionBody extends StatelessWidget {

	const _ContactsSectionBody();

	@override
	Widget build(BuildContext context) =>
		new FutureLoader(Configuration.getParams(context, reload: false), (AppParams params) {
			final locale = AppLocalizations.of(context);
			final contactsParams = params.contacts;
			return new Column(children: [
				if (!isNullOrEmpty(contactsParams.fbUserId))
					new _TextButtonedRow(locale.barScaffoldSettingsPanelContactsSectionFBLinkLabel, 
						() async => new FBLink(contactsParams.fbUserId).activate()),
				new _TextButtonedRow(
					locale.barScaffoldSettingsPanelContactsSectionSuggestionLinkLabel,
					() async => (await EmailLink.build(
						email: contactsParams.email, 
						body: locale.barScaffoldSettingsPanelContactsSectionSuggestionEmailBody, 
						subject: locale.barScaffoldSettingsPanelContactsSectionSuggestionEmailSubject
					)).activate()
				),
				new _TextButtonedRow(locale.barScaffoldSettingsPanelContactsSectionBugLinkLabel, 
					() async => (await EmailLink.build(
						email: contactsParams.email, 
						body: locale.barScaffoldSettingsPanelContactsSectionBugEmailBody, 
						subject: locale.barScaffoldSettingsPanelContactsSectionBugEmailSubject
					)).activate()),
				if (!isNullOrEmpty(contactsParams.appStoreId))
					new _TextButtonedRow(locale.barScaffoldSettingsPanelContactsSectionReviewLinkLabel, 
						() async => new AppStoreLink(contactsParams.appStoreId).activate())
			]);
		});
}

class _LanguageSubSectionHeader extends StatelessWidget {

	const _LanguageSubSectionHeader(): super();

	@override
	Widget build(BuildContext context) => 
		new _SubSectionHeader(AppLocalizations.of(context).barScaffoldSettingsPanelLanguageSectionLabel);
}

class _SubSectionHeader extends StatelessWidget {

	final String title;

	const _SubSectionHeader(this.title);

 	@override
  	Widget build(BuildContext context) => 
		new Row(
			children: [
				new Padding(
					padding: const EdgeInsets.only(left: 5, top: 10), 
					child: new Text(
						title,
						textAlign: TextAlign.left,
						style: const TextStyle(fontSize: Consts.biggerFontSize)
					)
				)
			]
		);
}

class _AppearanceSubSectionHeader extends StatelessWidget {

	const _AppearanceSubSectionHeader(): super();

	@override
	Widget build(BuildContext context) => 
		new _SubSectionHeader(AppLocalizations.of(context).barScaffoldSettingsPanelThemeSectionLabel);
}

class _SettingsSubSectionHeader extends StatelessWidget {

	const _SettingsSubSectionHeader(): super();

	@override
	Widget build(BuildContext context) => 
		new _SubSectionHeader(AppLocalizations.of(context).barScaffoldSettingsPanelStudySectionLabel);
}

class _TextButtonedRow extends StatelessWidget {
	
	final void Function() onPressed;

	final String label;

	const _TextButtonedRow(this.label, this.onPressed);

	@override
	Widget build(BuildContext context) => 
		new Row(
			children: <Widget>[new Flexible(child: new SizedBox(
				child: new TextButton(child: new Text(label), onPressed: onPressed),
				height: 40.0
			))]
		);
}

class _SettingsSectionHeader extends StatelessWidget {
	
	const _SettingsSectionHeader();

	@override
	Widget build(BuildContext context) => 
		_SectionHeader(AppLocalizations.of(context).barScaffoldSettingsPanelTitle);
}


class _ContactsSectionHeader extends StatelessWidget {
	
	const _ContactsSectionHeader();

	@override
	Widget build(BuildContext context) => 
		_SectionHeader(AppLocalizations.of(context).barScaffoldSettingsPanelContactsSectionLabel);
}

class _HelpSectionHeader extends StatelessWidget {
	
	const _HelpSectionHeader();

	@override
	Widget build(BuildContext context) => 
		_SectionHeader(AppLocalizations.of(context).barScaffoldSettingsPanelHelpSectionLabel);
}

class _SectionHeader extends StatelessWidget {
	
	final String title;

  	const _SectionHeader(this.title);

	@override
	Widget build(BuildContext context) =>
		new Row(
			mainAxisAlignment: MainAxisAlignment.center,
			children: [
				new Padding(
					padding: const EdgeInsets.only(left: 5), 
					child: new Text(
						title,
						style: const TextStyle(fontSize: Consts.largeFontSize)
					)
				)
			]
		);
}

class _SettingsPanel extends StatefulWidget {
    
	const _SettingsPanel();

    @override
    _SettingsPanelState createState() => new _SettingsPanelState();
}

class _SettingsOpenerButton extends StatelessWidget {

	const _SettingsOpenerButton();

    @override
    Widget build(BuildContext context) {
        return new IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Scaffold.of(context).openDrawer()
        );
    }
}

class BarScaffold extends StatelessWidget {

	final _SettingsOpenerButton _settingsOpener;

	final Widget body;

	final Widget bottomBar;

	final FloatingActionButton floatingActionButton;

	final List<Widget> barActions;

	final void Function() onNavGoingBack;

	final Widget _title;

	BarScaffold({ 
		String title, 
        @required Widget body,
        Widget bottomBar,
        FloatingActionButton floatingActionButton,
        List<Widget> barActions,
        void Function() onNavGoingBack,
		Widget titleWidget
    }): this._(
			title: title,
			body: body,
			bottomBar: bottomBar,
			floatingActionButton: floatingActionButton,
			barActions: barActions,
			onNavGoingBack: onNavGoingBack,
			titleWidget: titleWidget
		);

	BarScaffold.withSettings(String title, { 
        @required Widget body,
        Widget bottomBar,
        FloatingActionButton floatingActionButton,
        List<Widget> barActions,
        void Function() onNavGoingBack,
    }): this._(
			title: title,
			body: body,
			bottomBar: bottomBar,
			floatingActionButton: floatingActionButton,
			barActions: barActions,
			onNavGoingBack: onNavGoingBack,
			hasSettings: true
		);

    BarScaffold._({ 
		String title, 
        @required this.body,
        this.bottomBar,
    	this.floatingActionButton,
        this.barActions,
        this.onNavGoingBack,
        Widget titleWidget,
		bool hasSettings = false
    }): 
		_title = titleWidget ?? new BarTitle(title),
		_settingsOpener = (hasSettings ?? false) ? const _SettingsOpenerButton(): null;

	@override
	Widget build(BuildContext context) =>
		new Scaffold(
			drawer: _settingsOpener == null ? null: const _SettingsPanel(),
			appBar: onNavGoingBack == null ? 
				new AppBar(actions: barActions, leading: _settingsOpener, title: _title):
				new NavigationBar(_title, actions: barActions, onGoingBack: onNavGoingBack, 
					leading: _settingsOpener),
			body: body,
			bottomNavigationBar: bottomBar,
			floatingActionButton: floatingActionButton
		);
}

class BarTitle extends StatelessWidget {

	final String title;

	const BarTitle(this.title);

	@override
	Widget build(BuildContext context) => new OneLineText(title, textScaleFactor: 0.85);
}
