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
import '../widgets/loader.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/styled_dropdown.dart';

class _SettingsPanelState extends State<_SettingsPanel> {

    UserParams _params;

    String _originalParams;

	int _expandedPanelIndex = 0;

    @override
    Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
        final bloc = SettingsBlocProvider.of(context);
        return _params == null ? new FutureLoader<UserParams>(bloc.userParams, 
            (params) => _buildControlsFromParams(context, bloc, params, locale)): 
				_buildControls(context, bloc, locale);
    }

    Widget _buildControlsFromParams(BuildContext context, SettingsBloc bloc, UserParams params, 
		AppLocalizations locale) {
        _params = params;
        return _buildControls(context, bloc, locale);
    }

    Widget _buildControls(BuildContext context, SettingsBloc bloc, AppLocalizations locale) {
        if (_originalParams == null)
            _originalParams = _params.toJson();

        return new Drawer(
			child: new SingleChildScrollView(
				child: new Column(
					children: [
						new Padding(
							child: _buildSectionPanel(locale, bloc),
							padding: EdgeInsets.only(top: 30)
						)
					]
				)
			)  
		);
    }

	ExpansionPanelList _buildSectionPanel(AppLocalizations locale, SettingsBloc bloc) {
		return new ExpansionPanelList(
			children: [
				_buildSettingPanel(locale, 0, bloc),
				_buildContactsPanel(locale, 1),
				_buildHelpPanel(locale, 2)
			],
			expansionCallback: (panelIndex, isExpanded) {
				setState(() => _expandedPanelIndex = isExpanded ? null: panelIndex);	
			}
		);
	}

	ExpansionPanel _buildSettingPanel(AppLocalizations locale, int index, SettingsBloc bloc) {
		final children = <Widget>[];
		children.addAll(_buildLanguageSection(locale));
		children.addAll(_buildAppearanceSection(locale));
		children.addAll(_buildStudySection(locale));
		children.add(_buildButtons(bloc, locale));
		
		return _buildPanel(locale, index, 
			header: locale.barScaffoldSettingsPanelTitle,
			body: new Column(children: children)
		);
	}

    List<Widget> _buildLanguageSection(AppLocalizations locale) {
		return <Widget>[
            _buildSubsectionHeader(locale.barScaffoldSettingsPanelLanguageSectionLabel),
            new Row(children: <Widget>[
                _buildLanguageOption(Language.english, _params),
                _buildLanguageOption(Language.russian, _params)
            ])
        ];
    }


    Widget _buildLanguageOption(Language lang, UserParams params) {
        final isSelected = lang == params.interfaceLang;
        
        return new GestureDetector(
            child: new IconOption(
                icon: lang == Language.english ? AssetIcon.britishFlag : AssetIcon.russianFlag, 
                isSelected: isSelected
            ),
            onTap: () {
                if (isSelected)
                    return;

                setState(() => params.interfaceLang = lang);
            }
        );
    }

    List<Widget> _buildAppearanceSection(AppLocalizations locale) {
        return <Widget>[
            _buildSubsectionHeader(locale.barScaffoldSettingsPanelThemeSectionLabel),
            new Row(children: <Widget>[
                _buildAppearanceOption(AppTheme.dark),
                _buildAppearanceOption(AppTheme.light)
            ])
        ];
    }

    Widget _buildAppearanceOption(AppTheme theme) {
        final isSelected = theme == _params.theme;

        return new GestureDetector(
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

                setState(() => _params.theme = theme);
            }
        );
    }

	List<Widget> _buildStudySection(AppLocalizations locale) {
		final directionDic = PresentableEnum.mapStringValues(
			StudyDirection.values, locale);
		final sideDic = PresentableEnum.mapStringValues(CardSide.values, locale);

		return <Widget>[
            _buildSubsectionHeader(locale.barScaffoldSettingsPanelStudySectionLabel),
            new Row(children: <Widget>[
				_wrapWithExpandableContainer(
					new StyledDropdown(directionDic.keys, 
						label: locale.barScaffoldSettingsPanelStudySectionSortingCardOptionLabel,
						initialValue: _params.studyParams.direction.present(locale),
						onChanged: (newValue) {
							setState(() => _params.studyParams.direction = directionDic[newValue]);
						}
					)
				)
            ]),
			new Row(children: <Widget>[
				_wrapWithExpandableContainer(
					new StyledDropdown(sideDic.keys, 
						label: locale.barScaffoldSettingsPanelStudySectionCardSideOptionLabel,
						initialValue: _params.studyParams.cardSide.present(locale),
						onChanged: (newValue) {
							setState(() => _params.studyParams.cardSide = sideDic[newValue]);
						}
					)
				)
            ])
        ];
    }

	Widget _wrapWithExpandableContainer(Widget child) =>
		new Expanded(
			child: new Container(
				child: child, 
				margin: EdgeInsets.only(bottom: 5, top: 10)
			)
		);

    ExpansionPanel _buildContactsPanel(AppLocalizations locale, int index) {
		return _buildPanel(locale, index, 
			header: locale.barScaffoldSettingsPanelContactsSectionLabel,
			body: new Column(
				children: [
					_buildTextButtonedRow(locale.barScaffoldSettingsPanelContactsSectionFBLinkLabel, 
						() async => await new FBLink(widget.params.fbUserId).activate()),
					_buildTextButtonedRow(
						locale.barScaffoldSettingsPanelContactsSectionSuggestionLinkLabel,
						() async => await new EmailLink(
							email: widget.params.email, 
							body: locale.barScaffoldSettingsPanelContactsSectionSuggestionEmailBody, 
							subject: locale.barScaffoldSettingsPanelContactsSectionSuggestionEmailSubject
						).activate()
					),
					_buildTextButtonedRow(locale.barScaffoldSettingsPanelContactsSectionBugLinkLabel, 
						() async => await new EmailLink(
							email: widget.params.email, 
							body: locale.barScaffoldSettingsPanelContactsSectionBugEmailBody, 
							subject: locale.barScaffoldSettingsPanelContactsSectionBugEmailSubject
						).activate()),
					_buildTextButtonedRow(locale.barScaffoldSettingsPanelContactsSectionReviewLinkLabel, 
						() async => await new AppStoreLink(widget.params.appStoreId).activate())
				]) 
		);
    }

	ExpansionPanel _buildPanel(AppLocalizations locale, int index, 
		{ String header, Widget body }
	) => new ExpansionPanel(
			headerBuilder: (context, isExpanded) => _buildPanelHeader(header),
			body: body,
			isExpanded: _expandedPanelIndex == index
		);

    Widget _buildSubsectionHeader(String title) =>
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

    Widget _buildPanelHeader(String title) {
        return new Row(
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

	Widget _buildTextButtonedRow(String label, Function() onPressed) {
		return new Row(
			children: <Widget>[new Flexible(child: new Container(
				child: new TextButton(child: new Text(label), onPressed: onPressed),
				height: 40.0
			))]
		);
	}

    ExpansionPanel _buildHelpPanel(AppLocalizations locale, int index) {
		return _buildPanel(locale, index,
			header: locale.barScaffoldSettingsPanelHelpSectionLabel,
			body: new Column(
				children: [
					_buildTextButtonedRow(locale.mainScreenStudyModeMenuItemLabel, 
						() => Router.goToStudyHelp(context)),
					_buildTextButtonedRow(locale.mainScreenWordPacksMenuItemLabel, 
						() => Router.goToPackHelp(context)),
					_buildTextButtonedRow(locale.mainScreenWordCardsMenuItemLabel, 
						() => Router.goToCardHelp(context))
				]
			)
		);
    }

    Widget _buildButtons(SettingsBloc bloc, AppLocalizations locale) {
        return new Row(
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
        );
    }
}

class _SettingsPanel extends StatefulWidget {
    
	final ContactsParams params;

	_SettingsPanel(this.params);

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

class BarScaffold extends Scaffold {

	BarScaffold(String title, { 
        @required Widget body,
        Widget bottomBar,
        FloatingActionButton floatingActionButton,
        List<Widget> barActions,
		ContactsParams contactsParams,
        void Function() onNavGoingBack
    }): this._(title,
			body: body,
			bottomBar: bottomBar,
			floatingActionButton: floatingActionButton,
			barActions: barActions,
			onNavGoingBack: onNavGoingBack
		);

	BarScaffold.withSettings(String title, { 
        @required Widget body,
		@required ContactsParams contactsParams,
        Widget bottomBar,
        FloatingActionButton floatingActionButton,
        List<Widget> barActions,
        void Function() onNavGoingBack
    }): this._(title,
			body: body,
			contactsParams: contactsParams,
			bottomBar: bottomBar,
			floatingActionButton: floatingActionButton,
			barActions: barActions,
			onNavGoingBack: onNavGoingBack
		);

    BarScaffold._(String title, { 
        @required Widget body,
        Widget bottomBar,
        FloatingActionButton floatingActionButton,
        List<Widget> barActions,
		ContactsParams contactsParams,
        void Function() onNavGoingBack
    }): super(
        drawer: contactsParams == null ? null: new _SettingsPanel(contactsParams), 
        appBar: _buildAppBar(
			new Text(title, textScaleFactor: 0.85, 
				softWrap: true, overflow: TextOverflow.visible),
			actions: barActions, onGoingBack: onNavGoingBack, 
			showSettings: contactsParams != null
		),
        body: body,
        bottomNavigationBar: bottomBar,
        floatingActionButton: floatingActionButton
    );

    static Widget _buildAppBar(Widget title, 
        { List<Widget> actions,  void Function() onGoingBack, bool showSettings }) {

        final openerBtn = (showSettings ?? false) ? new _SettingsOpenerButton(): null;
        return onGoingBack == null ? 
            new AppBar(actions: actions, leading: openerBtn, title: title):
            new NavigationBar(title, actions: actions, onGoingBack: onGoingBack, 
                leading: openerBtn);
    }
}
