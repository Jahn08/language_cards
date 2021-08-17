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
										body: new _SettingsSectionBody()
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
							padding: EdgeInsets.only(top: 30)
						)
					]
				)
			)  
		);

	ExpansionPanel _buildPanel(int index, { Widget header, Widget body }) => 
		new ExpansionPanel(
			headerBuilder: (context, _) => header,
			body: body,
			isExpanded: _expandedPanelIndex == index
		);
}

class _SettingsSectionBodyState extends State<_SettingsSectionBody> {
	
    UserParams _params;

    String _originalParams;

	@override
	Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
        final bloc = SettingsBlocProvider.of(context);
        
		return new FutureLoader<UserParams>(bloc.userParams, (params) {
			if (_params == null)
				_params = params;

			final directionDic = PresentableEnum.mapStringValues(StudyDirection.values, locale);
			final sideDic = PresentableEnum.mapStringValues(CardSide.values, locale);
			
			return new Column(children: [
				const _LanguageSubSectionHeader(),
				new _LanguageSettingsSection(
					_params.interfaceLang, 
					(newLang) => setState(() => _params.interfaceLang = newLang)
				),
				const _AppearanceSubSectionHeader(),
				new _AppearanceSettingsSection(
					_params.theme, 
					(newTheme) => setState(() => _params.theme = newTheme)
				),
				const _SettingsSubSectionHeader(),
				new _StudySettingsSectionRow(
					options: directionDic.keys,
					inintialValue: _params.studyParams.direction.present(locale),
					label: locale.barScaffoldSettingsPanelStudySectionSortingCardOptionLabel,
					onValueChanged: (newValue) {
						setState(() => _params.studyParams.direction = directionDic[newValue]);
					}
				),
				new _StudySettingsSectionRow(
					options: sideDic.keys,
					inintialValue: _params.studyParams.cardSide.present(locale),
					label: locale.barScaffoldSettingsPanelStudySectionCardSideOptionLabel,
					onValueChanged: (newValue) {
						setState(() => _params.studyParams.cardSide = sideDic[newValue]);
					}
				),
				new Row(
					mainAxisAlignment: MainAxisAlignment.spaceEvenly,
					children: [
						new ElevatedButton(
							child: new Text(locale.barScaffoldSettingsPanelResettingButtonLabel),
							onPressed: () => setState(() => _params = new UserParams())
						),
						new ElevatedButton(
							child: new Text(locale.barScaffoldSettingsPanelApplyingButtonLabel),
							onPressed: _originalParams == _params.toJson() ? null: () async {
								await bloc.save(_params);
								Navigator.pop(context);
							}
						)
					] 
				)
			]);
		});
	}
}

class _SettingsSectionBody extends StatefulWidget {
	
	@override
	State<StatefulWidget> createState() => new _SettingsSectionBodyState();
}

class _StudySettingsSectionRow extends StatelessWidget {

	final Iterable<String> options;

	final String inintialValue;

	final String label;

	final void Function(String) onValueChanged;

	_StudySettingsSectionRow({ this.options, this.inintialValue, this.onValueChanged, this.label });

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
						margin: EdgeInsets.only(bottom: 5, top: 10)
					)
            	)
        ]);	
}

class _AppearanceSettingsSection extends StatelessWidget {
	
	final AppTheme theme;

	final void Function(AppTheme) onThemeChanged;

	_AppearanceSettingsSection(this.theme, this.onThemeChanged);

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

	_AppearanceOption({ this.theme, this.isSelected, this.onTap });

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

	_LanguageSettingsSection(this.interfaceLang, this.onLangChanged);

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

	_LanguageOption({ this.lang, this.isSelected, this.onTap });

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

				this.onTap();
            }
        );
}

class _HelpSectionBody extends _SimpleSectionBody {

	const _HelpSectionBody();

	@override
	Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
		return new Column(
			children: [
				buildTextButtonedRow(locale.mainScreenStudyModeMenuItemLabel, 
					() => Router.goToStudyHelp(context)),
				buildTextButtonedRow(locale.mainScreenWordPacksMenuItemLabel, 
					() => Router.goToPackHelp(context)),
				buildTextButtonedRow(locale.mainScreenWordCardsMenuItemLabel, 
					() => Router.goToCardHelp(context))
			]
		);
	}
}

class _ContactsSectionBody extends _SimpleSectionBody {

	const _ContactsSectionBody();

	@override
	Widget build(BuildContext context) =>
		new FutureLoader(Configuration.getParams(context, reload: false), (AppParams params) {
			final locale = AppLocalizations.of(context);
			final contactsParams = params.contacts;
			return new Column(children: [
				if (!isNullOrEmpty(contactsParams.fbUserId))
					buildTextButtonedRow(locale.barScaffoldSettingsPanelContactsSectionFBLinkLabel, 
						() async => await new FBLink(contactsParams.fbUserId).activate()),
				buildTextButtonedRow(
					locale.barScaffoldSettingsPanelContactsSectionSuggestionLinkLabel,
					() async => await (await EmailLink.build(
						email: contactsParams.email, 
						body: locale.barScaffoldSettingsPanelContactsSectionSuggestionEmailBody, 
						subject: locale.barScaffoldSettingsPanelContactsSectionSuggestionEmailSubject
					)).activate()
				),
				buildTextButtonedRow(locale.barScaffoldSettingsPanelContactsSectionBugLinkLabel, 
					() async => await (await EmailLink.build(
						email: contactsParams.email, 
						body: locale.barScaffoldSettingsPanelContactsSectionBugEmailBody, 
						subject: locale.barScaffoldSettingsPanelContactsSectionBugEmailSubject
					)).activate()),
				buildTextButtonedRow(locale.barScaffoldSettingsPanelContactsSectionReviewLinkLabel, 
					() async => await new AppStoreLink(contactsParams.appStoreId).activate())
			]);
		});
}

class _LanguageSubSectionHeader extends _SubSectionHeader {

	const _LanguageSubSectionHeader(): super();

	@override
	Widget build(BuildContext context) => 
		buildHeader(AppLocalizations.of(context).barScaffoldSettingsPanelLanguageSectionLabel);
}

abstract class _SubSectionHeader extends StatelessWidget {

	const _SubSectionHeader();

	@protected
	Widget buildHeader(String title) => 
		new Row(
			mainAxisAlignment: MainAxisAlignment.start,
			children: [
				new Padding(
					padding: EdgeInsets.only(left: 5, top: 10), 
					child: new Text(
						title,
						textAlign: TextAlign.left,
						style: new TextStyle(fontSize: Consts.biggerFontSize)
					)
				)
			]
		);
}

class _AppearanceSubSectionHeader extends _SubSectionHeader {

	const _AppearanceSubSectionHeader(): super();

	@override
	Widget build(BuildContext context) => 
		buildHeader(AppLocalizations.of(context).barScaffoldSettingsPanelThemeSectionLabel);
}

class _SettingsSubSectionHeader extends _SubSectionHeader {

	const _SettingsSubSectionHeader(): super();

	@override
	Widget build(BuildContext context) => 
		buildHeader(AppLocalizations.of(context).barScaffoldSettingsPanelStudySectionLabel);
}

abstract class _SimpleSectionBody extends StatelessWidget {

	const _SimpleSectionBody();

	@protected
	Widget buildTextButtonedRow(String label, Function() onPressed) {
		return new Row(
			children: <Widget>[new Flexible(child: new Container(
				child: new TextButton(child: new Text(label), onPressed: onPressed),
				height: 40.0
			))]
		);
	}
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
			crossAxisAlignment: CrossAxisAlignment.center,
			mainAxisAlignment: MainAxisAlignment.center,
			children: [
				new Padding(
					padding: EdgeInsets.only(left: 5), 
					child: new Text(
						title,
						style: new TextStyle(fontSize: Consts.largeFontSize)
					)
				)
			]
		);
}

class _SettingsPanel extends StatefulWidget {
    
	_SettingsPanel();

    @override
    _SettingsPanelState createState() => new _SettingsPanelState();
}

class _SettingsOpenerButton extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return new IconButton(
            icon: new Icon(Icons.settings),
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
		ContactsParams contactsParams,
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
		_settingsOpener = (hasSettings ?? false) ? new _SettingsOpenerButton(): null;

	@override
	Widget build(BuildContext context) {
		return new Scaffold(
			drawer: _settingsOpener == null ? null: new _SettingsPanel(),
			appBar: onNavGoingBack == null ? 
				new AppBar(actions: barActions, leading: _settingsOpener, title: _title):
				new NavigationBar(_title, actions: barActions, onGoingBack: onNavGoingBack, 
					leading: _settingsOpener),
			body: body,
			bottomNavigationBar: bottomBar,
			floatingActionButton: floatingActionButton
		);
	}    
}

class BarTitle extends StatelessWidget {

	final String title;

	const BarTitle(this.title);

	@override
	Widget build(BuildContext context) => new OneLineText(title, textScaleFactor: 0.85);
}
