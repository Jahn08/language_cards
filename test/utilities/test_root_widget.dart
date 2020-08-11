import 'package:flutter/material.dart';

class TestRootWidget extends StatelessWidget {
    final Function(BuildContext) _onBuildCallback;

    TestRootWidget({Function(BuildContext) onBuilding}):
        _onBuildCallback = onBuilding;

    @override
    Widget build(BuildContext context) {
        if (_onBuildCallback != null)
            _onBuildCallback(context);

        return new Scaffold(
            appBar: new AppBar(
                title: new Text('Test Widget'),
            ),
            body: new Container()
        );
    }
}
