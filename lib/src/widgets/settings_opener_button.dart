import 'package:flutter/material.dart';

class SettingsOpenerButton extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
        return new IconButton(
            icon: new Icon(Icons.settings),
            onPressed: () => Scaffold.of(context).openDrawer()
        );
    }
}
