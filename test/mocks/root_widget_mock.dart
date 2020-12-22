import 'package:flutter/material.dart';

class RootWidgetMock extends StatelessWidget {
    final Widget _child;
    
    final Function(BuildContext) _onBuildCallback;

    final bool _noBar;

    RootWidgetMock({ Function(BuildContext) onBuilding, Widget child, bool noBar }):
        _onBuildCallback = onBuilding,
        _child = child,
        _noBar = noBar ?? false;

    @override
    Widget build(BuildContext context) {
        if (_onBuildCallback != null)
            _onBuildCallback(context);

        return _noBar ? _child: new Scaffold(
            appBar: new AppBar(
                title: new Text('Test Widget'),
            ),
            body: new Container(
                child: _child
            )
        );
    }

    static Widget buildAsAppHome({ Function(BuildContext) onBuilding, 
        Widget child, bool noBar }) =>
        new MaterialApp(onGenerateRoute: (settings) => new MaterialPageRoute(
            builder: (context) => 
                new RootWidgetMock(onBuilding: onBuilding, child: child, noBar: noBar)
        ));
}
