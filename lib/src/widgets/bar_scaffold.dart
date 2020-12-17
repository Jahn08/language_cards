import 'package:flutter/material.dart';
import './asset_icon.dart';
import './icon_option.dart';
import '../blocs/settings_bloc.dart';
import '../models/language.dart';
import '../models/user_params.dart';
import '../widgets/loader.dart';
import '../widgets/navigation_bar.dart';

class _SettingsPanelState extends State<_SettingsPanel> {

    UserParams _params;

    String _originalParams;

    @override
    Widget build(BuildContext context) {
        final bloc = SettingsBlocProvider.of(context);
        return _params == null ? new FutureLoader<UserParams>(bloc.userParams, 
            (params) => _buildControlsFromParams(bloc, params)): _buildControls(bloc);
    }

    Widget _buildControlsFromParams(SettingsBloc bloc, UserParams params) {
        _params = params;
        return _buildControls(bloc);
    }

    Widget _buildControls(SettingsBloc bloc) {
        final children = <Widget>[_buildHeader()];
        
        if (_originalParams == null)
            _originalParams = _params.toJson();
        
        children.addAll(_buildLanguageSection());
        children.addAll(_buildAppearanceSection());
        children.addAll(_buildContactsSection());
        children.addAll(_buildHelpSection());

        children.add(_buildApplyButton(bloc));

        return new Drawer(child: new ListView(children: children));
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

    List<Widget> _buildLanguageSection() {
        return <Widget>[
            _buildSubsectionHeader('Language'),
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

    List<Widget> _buildAppearanceSection() {
        return <Widget>[
            _buildSubsectionHeader('Appearance'),
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

    Widget _buildApplyButton(SettingsBloc bloc) {
        return new Column(
            children: [
                new RaisedButton(
                    child: new Text('Reset'),
                    onPressed: () => setState(() => _params = new UserParams())
                ),
                new RaisedButton(
                    child: new Text('Apply'),
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
