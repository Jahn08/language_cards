import 'package:flutter/material.dart';

class NavigationBar extends AppBar {
  NavigationBar(Widget title,
      {required Function() onGoingBack, Widget? leading, List<Widget>? actions})
      : super(
            automaticallyImplyLeading: false,
            title: new Row(children: <Widget>[
              new BackButton(onPressed: () => onGoingBack.call()),
              if (leading != null) leading,
              new Expanded(child: title)
            ]),
            actions: actions);
}
