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
                _buildRow(flex: 2),
                _buildRow(children: [
                    _buildMenuItem('Study Mode', Icons.school, 
                        () => Router.goToStudyPreparation(context))
                ]),
                _buildRow(children: [
                    _buildMenuItem('Word Packs', Icons.library_books, 
                        () => Router.goToPackList(context)),
                    _buildMenuItem('Word Cards', App.cardListIcon, 
                        () => Router.goToCardList(context))
                ])
            ]
        );
    }

    Widget _buildRow({ List<Widget> children, int flex }) => 
        new Flexible(
            fit: FlexFit.tight,
            flex: flex ?? 1,
            child: new Row(
                crossAxisAlignment: CrossAxisAlignment.stretch, 
                children: children ?? []
            )
        );

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
