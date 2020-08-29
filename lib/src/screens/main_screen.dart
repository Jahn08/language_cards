import 'package:flutter/material.dart';
import '../widgets/settings_panel.dart';
import '../widgets/settings_opener_button.dart';
import '../blocs/settings_bloc.dart';
import '../router.dart';

class MainScreen extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return new Scaffold(
            appBar: new AppBar(
                title: new Text('Language Cards'),
                actions: <Widget>[new SettingsOpenerButton()]
            ),
            endDrawer: new SettingsBlocProvider(child: new SettingsPanel()),
            body: _buildBody(context)
        );
    }

    Widget _buildBody(BuildContext context) {
        return new Column(
            children: <Widget>[
                new RaisedButton.icon(
                    onPressed: () => Router.goToNewCard(context), 
                    icon: new Icon(Icons.add_circle), 
                    label: new Text('New Card')
                )
            ]
        );
    }
}
