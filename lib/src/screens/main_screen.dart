import 'package:flutter/material.dart' hide Router;
import '../app.dart';
import '../router.dart';
import '../widgets/bar_scaffold.dart';

class MainScreen extends StatelessWidget {

    @override
    Widget build(BuildContext context) {

        return new BarScaffold('Language Cards',
            showSettings: true,
            body: _buildMenu(context),
        );
    }

    Widget _buildMenu(BuildContext context) {
        return new Column(
            children: [
                _buildEmptyMenuRow(),
                _buildEmptyMenuRow(),
                _buildMenuRow([
                    _buildMenuItem('Study Mode', Icons.school, 
                        () => Router.goToStudyMode(context))
                ]),
                _buildMenuRow([
                    _buildMenuItem('Word Packs', Icons.library_books, 
                        () => Router.goToPackList(context)),
                    _buildMenuItem('Word Cards', App.cardListIcon, 
                        () => Router.goToCardList(context))
                ])
            ]
        );
    }

    Widget _buildEmptyMenuRow() =>  _buildMenuRow([]);

    Widget _buildMenuRow(List<Widget> children) {
        return new Expanded(
            child: new Row(
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: children
            )
        );
    }

    Widget _buildMenuItem(String title, IconData icon, void Function() onClick) {
        return new Expanded(
            child: new Container(
                padding: EdgeInsets.all(10),
                child: new ElevatedButton.icon(
                    style: new ButtonStyle(
                        textStyle: MaterialStateProperty.resolveWith(
                            (states) => new TextStyle(
                                fontSize: 20
                            )) 
                    ),
                    onPressed: onClick, 
                    icon: new Icon(icon), 
                    label: new Text(title)
                )
            )
        );
    }
}
