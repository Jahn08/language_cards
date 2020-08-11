import 'package:flutter/material.dart';
import './asset_icon.dart';
import './icon_option.dart';
import '../blocs/settings_bloc_provider.dart';

class SettingsPanelState extends State<SettingsPanel> {
    @override
    Widget build(BuildContext context) {
        final bloc = SettingsBlocProvider.of(context);

        final children = <Widget>[_buildHeader()];
        children.addAll(_buildLanguageSection(bloc));
        children.addAll(_buildAppearanceSection(bloc));
        children.addAll(_buildContactsSection());
        children.addAll(_buildHelpSection());

        return new Drawer(
            child: new ListView(children: children)
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

    List<Widget> _buildLanguageSection(SettingsBloc bloc) {
        return <Widget>[
            _buildSubsectionHeader('Language'),
            new Row(children: <Widget>[
                _buildLanguageOption(AppLanguage.english, bloc),
                _buildLanguageOption(AppLanguage.russian, bloc)
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

    Widget _buildLanguageOption(AppLanguage lang, SettingsBloc bloc) {
        final isSelected = lang == bloc.language;
        
        return new GestureDetector(
            child: new IconOption(
                icon: lang == AppLanguage.english ? AssetIcon.britishFlag : AssetIcon.russianFlag, 
                isSelected: isSelected
            ),
            onTap: () {
                if (isSelected)
                    return;

                setState(() => bloc.language = lang);
            }
        );  
    }

    List<Widget> _buildAppearanceSection(SettingsBloc bloc) {
        return <Widget>[
            _buildSubsectionHeader('Appearance'),
            new Row(children: <Widget>[
                _buildAppearanceOption(AppTheme.dark, bloc),
                _buildAppearanceOption(AppTheme.light, bloc)
            ])
        ];
    }

    Widget _buildAppearanceOption(AppTheme theme, SettingsBloc bloc) {
        final isSelected = theme == bloc.theme;

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

                setState(() => bloc.theme = theme);
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
}

class SettingsPanel extends StatefulWidget {
    @override
    SettingsPanelState createState() => new SettingsPanelState();
}
