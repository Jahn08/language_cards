import 'package:flutter/material.dart';

class TestRootWidget extends StatelessWidget {
    final Widget _child;
    final Function(BuildContext) _onBuildCallback;

    TestRootWidget({ Function(BuildContext) onBuilding, Widget child }):
        _onBuildCallback = onBuilding,
        _child = child;

    @override
    Widget build(BuildContext context) {
        if (_onBuildCallback != null)
            _onBuildCallback(context);

        return new Scaffold(
            appBar: new AppBar(
                title: new Text('Test Widget'),
            ),
            body: new Container(
                child: _child
            )
        );
    }

    static Widget buildAsAppHome({ Function(BuildContext) onBuilding, Widget child }) =>
        new MaterialApp(onGenerateRoute: (settings) => new MaterialPageRoute(
            builder: (context) => new TestRootWidget(onBuilding: onBuilding, child: child)
        ));
}
