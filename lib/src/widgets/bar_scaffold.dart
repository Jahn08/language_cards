import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import './asset_icon.dart';
import './icon_option.dart';
import '../blocs/settings_bloc.dart';
import '../models/language.dart';
import '../models/user_params.dart';
import '../utilities/enum.dart';
import '../widgets/loader.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/styled_dropdown.dart';

class _SettingsPanelState extends State<_SettingsPanel> {

	static const double _bigFontSize = 20;

    UserParams _params;

    String _originalParams;

    @override
    Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
        final bloc = SettingsBlocProvider.of(context);
        return _params == null ? new FutureLoader<UserParams>(bloc.userParams, 
            (params) => _buildControlsFromParams(bloc, params, locale)): 
				_buildControls(bloc, locale);
    }

    Widget _buildControlsFromParams(SettingsBloc bloc, UserParams params, 
		AppLocalizations locale) {
        _params = params;
        return _buildControls(bloc, locale);
    }

    Widget _buildControls(SettingsBloc bloc, AppLocalizations locale) {
        final children = <Widget>[_buildHeader(locale)];
        
        if (_originalParams == null)
            _originalParams = _params.toJson();
        
        children.addAll(_buildLanguageSection(locale));
        children.addAll(_buildAppearanceSection(locale));
        children.addAll(_buildStudySection(locale));
        children.addAll(_buildContactsSection(locale));
        children.addAll(_buildHelpSection(locale));

        children.add(_buildApplyButton(bloc, locale));

        return new Drawer(child: new ListView(children: children));
    }

    Widget _buildHeader(AppLocalizations locale) {
        return new Container(
            child:new DrawerHeader(
                child: new Text(
					locale.barScaffoldSettingsPanelTitle,
                    style: new TextStyle(
						fontSize: _bigFontSize,
						fontWeight: FontWeight.w800
					),
                    textAlign: TextAlign.center
                )
            ),
            height: 60
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

    Widget _buildSubsectionHeader(String title) {
        return new Padding(
            padding: EdgeInsets.only(left: 5), 
            child: new Text(
                title,
                style: new TextStyle(fontSize: _bigFontSize)
            ));
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
		final directionDic = Enum.mapStringValues(StudyDirection.values);
		final sideDic = Enum.mapStringValues(CardSide.values);

		return <Widget>[
            _buildSubsectionHeader(locale.barScaffoldSettingsPanelStudySectionLabel),
            new Row(children: <Widget>[
				_wrapWithExpandableContainer(
					new StyledDropdown(directionDic.keys, 
						label: locale.barScaffoldSettingsPanelStudySectionSortingCardOptionLabel,
						initialValue: Enum.stringifyValue(_params.studyParams.direction),
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
						initialValue: Enum.stringifyValue(_params.studyParams.cardSide),
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

    List<Widget> _buildContactsSection(AppLocalizations locale) {
        return <Widget>[
            _buildSubsectionHeader(locale.barScaffoldSettingsPanelContactsSectionLabel)
        ];
    }

    List<Widget> _buildHelpSection(AppLocalizations locale) {
        return <Widget>[
            _buildSubsectionHeader(locale.barScaffoldSettingsPanelHelpSectionLabel)
        ];
    }

    Widget _buildApplyButton(SettingsBloc bloc, AppLocalizations locale) {
        return new Column(
            children: [
                new RaisedButton(
                    child: new Text(locale.barScaffoldSettingsPanelResettingButtonLabel),
                    onPressed: () => setState(() => _params = new UserParams())
                ),
                new RaisedButton(
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
        bool showSettings,
        BottomNavigationBar bottomNavigationBar,
        FloatingActionButton floatingActionButton,
        List<Widget> barActions,
        void Function() onNavGoingBack
    }): super(
        drawer: (showSettings ?? false) ? new _SettingsPanel(): null, 
        appBar: _buildAppBar(title, actions: barActions, onGoingBack: onNavGoingBack, 
            showSettings: showSettings),
        body: body,
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton
    );

    static Widget _buildAppBar(String title, 
        { List<Widget> actions,  void Function() onGoingBack, bool showSettings }) {

        final openerBtn = (showSettings ?? false) ? new _SettingsOpenerButton(): null;
        return onGoingBack == null ? 
            new AppBar(actions: actions, leading: openerBtn, title: new Text(title)):
            new NavigationBar(new Text(title), actions: actions, onGoingBack: onGoingBack, 
                leading: openerBtn);
    }
}
