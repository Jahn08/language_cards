import 'package:flutter/material.dart';

class IconedButton extends StatelessWidget {
  final Widget labelWidget;

  final Icon icon;

  final void Function() onPressed;

  IconedButton(
      {@required String label,
      @required Icon icon,
      @required void Function() onPressed})
      : this.labelWidget(
            labelWidget: new Text(label), icon: icon, onPressed: onPressed);

  const IconedButton.labelWidget(
      {@required this.labelWidget,
      @required this.icon,
      @required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return new InkWell(
        onTap: onPressed,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[icon, labelWidget]));
  }
}
