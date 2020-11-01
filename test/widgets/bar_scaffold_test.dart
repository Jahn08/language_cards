import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/widgets/bar_scaffold.dart';
import 'package:language_cards/src/widgets/navigation_bar.dart';
import '../utilities/assured_finder.dart';
import '../utilities/randomiser.dart';
import '../utilities/test_root_widget.dart';

void main() {

    testWidgets('Renders a scaffold with passed widgets and title for a non-navigational bar',
        (tester) async {
            final expectedTitle = Randomiser.nextString();
            final expectedBodyText = Randomiser.nextString();

            final expectedBarActionText = Randomiser.nextString();
            final expectedBarAction = _buildBarAction(expectedBarActionText);

            final bottomNavBarFirstItemTitle = Randomiser.nextString();
            final bottomNavBarSecondItemTitle = Randomiser.nextString();

            final bottomNavBarKey = new Key(Randomiser.nextString());
            final floatingActionBtnKey = new Key(Randomiser.nextString());
            
            final navBarItemIcon = new Icon(Icons.ac_unit);

            await tester.pumpWidget(TestRootWidget.buildAsAppHome(
                child: new BarScaffold(expectedTitle, 
                    bottomNavigationBar: new BottomNavigationBar(
                        key: bottomNavBarKey,
                        items: <BottomNavigationBarItem>[
                            new BottomNavigationBarItem(
                                icon: navBarItemIcon,
                                title: new Text(bottomNavBarFirstItemTitle)
                            ),
                            new BottomNavigationBarItem(
                                icon: navBarItemIcon,
                                title: new Text(bottomNavBarSecondItemTitle)
                            )
                        ]
                    ),
                    body: new Text(expectedBodyText),
                    barActions: <Widget>[expectedBarAction],
                    floatingActionButton: new FloatingActionButton(
                        key: floatingActionBtnKey,
                        onPressed: null
                    )
                )
            ));

            AssuredFinder.findOne(label: expectedTitle, shouldFind: true);
            AssuredFinder.findOne(label: expectedBodyText, shouldFind: true);

            AssuredFinder.findOne(type: NavigationBar, shouldFind: false);
            AssuredFinder.findOne(label: expectedBarActionText, shouldFind: true);

            AssuredFinder.findOne(key: bottomNavBarKey, shouldFind: true);
            AssuredFinder.findOne(label: bottomNavBarFirstItemTitle, shouldFind: true);
            AssuredFinder.findOne(label: bottomNavBarSecondItemTitle, shouldFind: true);

            AssuredFinder.findOne(key: expectedBarAction.key, shouldFind: true);
            AssuredFinder.findOne(key: floatingActionBtnKey, shouldFind: true);
        });

    testWidgets('Renders a navigational bar with actions when a navigation callback is provided', 
        (tester) async {
            final expectedBarActionText = Randomiser.nextString();
            final expectedBarAction = _buildBarAction(expectedBarActionText);

            await tester.pumpWidget(TestRootWidget.buildAsAppHome(
                child: new BarScaffold(Randomiser.nextString(), 
                    body: new Text(Randomiser.nextString()),
                    onNavGoingBack: () {},
                    barActions: <Widget>[expectedBarAction]
                )
            ));

            AssuredFinder.findOne(label: expectedBarActionText, type: NavigationBar,
                shouldFind: true);
            AssuredFinder.findOne(key: expectedBarAction.key, shouldFind: true);
        });

    testWidgets('Renders no button to open the settings panel by default', (tester) async {
        await tester.pumpWidget(TestRootWidget.buildAsAppHome(
            child: new BarScaffold(Randomiser.nextString(), 
                body: new Text(Randomiser.nextString())
            )
        ));

        _assureSettingsApplyBtn(false);
    });

    testWidgets('Renders a button to open the settings panel', (tester) async {
        await tester.pumpWidget(TestRootWidget.buildAsAppHome(
            child: new BarScaffold(Randomiser.nextString(), 
                body: new Text(Randomiser.nextString()),
                showSettings: true
            )
        ));

        _assureSettingsApplyBtn(true);
    });
}

FlatButton _buildBarAction(String label) => new FlatButton(
    key: new Key(Randomiser.nextString()),
    child: new Text(label),
    onPressed: null
);

Finder _assureSettingsApplyBtn(bool shouldFind) =>
    AssuredFinder.findOne(icon: Icons.settings, shouldFind: shouldFind);
