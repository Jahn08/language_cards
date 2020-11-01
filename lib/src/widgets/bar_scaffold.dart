import 'package:flutter/material.dart';
import './asset_icon.dart';
import './icon_option.dart';
import '../blocs/settings_bloc.dart';
import '../models/language.dart';
import '../models/user_params.dart';
import '../widgets/loader.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/settings_opener_button.dart';

class _SettingsPanelState extends State<_SettingsPanel> {

    String _originalParams;

    @override
    Widget build(BuildContext context) {
        final bloc = SettingsBlocProvider.of(context);
        return new FutureLoader<UserParams>(bloc.userParams, (params) {
                final children = <Widget>[_buildHeader()];
                
                if (_originalParams == null)
                    _originalParams = params.toJson();
                
                children.addAll(_buildLanguageSection(params));
                children.addAll(_buildAppearanceSection(params));
                children.addAll(_buildContactsSection());
                children.addAll(_buildHelpSection());

                children.add(_buildApplyButton(bloc, params));

                return new Drawer(child: new ListView(children: children));
            }
        );
    }

    Widget _buildHeader() {
        return new Container(
            child:new DrawerHeader(
                child: new Text(
                    'Settings',
                    style: new TextStyle(fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center
                )
            ),
            height: 50
        );
    }

    List<Widget> _buildLanguageSection(UserParams params) {
        return <Widget>[
            _buildSubsectionHeader('Language'),
            new Row(children: <Widget>[
                _buildLanguageOption(Language.english, params),
                _buildLanguageOption(Language.russian, params)
            ])
        ];
    }

    Widget _buildSubsectionHeader(String title) {
        return new Padding(
            padding: EdgeInsets.only(left: 5), 
            child: new Text(
                title,
                style: new TextStyle(
                    fontWeight: FontWeight.bold
                )
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

    List<Widget> _buildAppearanceSection(UserParams params) {
        return <Widget>[
            _buildSubsectionHeader('Appearance'),
            new Row(children: <Widget>[
                _buildAppearanceOption(AppTheme.dark, params),
                _buildAppearanceOption(AppTheme.light, params)
            ])
        ];
    }

    Widget _buildAppearanceOption(AppTheme theme, UserParams params) {
        final isSelected = theme == params.theme;

        return new GestureDetector(
            child: new IconOption(
                icon: new Container(
                    height: AssetIcon.HEIGHT,
                    width: AssetIcon.WIDTH,
                    color: Colors.blueGrey[theme == AppTheme.dark ? 900: 100]
                ), 
                isSelected: isSelected
            ),
            onTap: () {
                if (isSelected)
                    return;

                setState(() => params.theme = theme);
            }
        );
    }

    List<Widget> _buildContactsSection() {
        return <Widget>[
            _buildSubsectionHeader('Contacts')
        ];
    }

    List<Widget> _buildHelpSection() {
        return <Widget>[
            _buildSubsectionHeader('Help')
        ];
    }

    Widget _buildApplyButton(SettingsBloc bloc, UserParams params) {
        return new Center(
            child: new RaisedButton(
                child: new Text('Apply'),
                onPressed: _originalParams == params.toJson() ? null: () async {
                    await bloc.save();
                    Navigator.pop(context);
                }
            )
        );
    }
}

class _SettingsPanel extends StatefulWidget {
    
    @override
    _SettingsPanelState createState() => new _SettingsPanelState();
}

class BarScaffold extends Scaffold {

    BarScaffold(String title, { 
        bool showSettings,
        Widget bottomNavigationBar,
        Widget body,
        Widget floatingActionButton,
        List<Widget> barActions,
        void Function() onNavGoingBack,
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

        final openerBtn = (showSettings ?? false) ? new SettingsOpenerButton(): null;
        return onGoingBack == null ? 
            new AppBar(actions: actions, leading: openerBtn, title: new Text(title)):
            new NavigationBar(new Text(title), actions: actions, onGoingBack: onGoingBack, 
                leading: openerBtn);
    }
}
