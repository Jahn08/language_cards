import 'package:flutter/widgets.dart';
import '../utilities/styler.dart';

class UnderlinedContainer extends StatelessWidget {
  final Widget child;

  const UnderlinedContainer(this.child);

  @override
  Widget build(BuildContext context) {
    return new Container(
        decoration: new BoxDecoration(
            border: new Border(
                bottom:
                    new BorderSide(color: new Styler(context).dividerColor))),
        child: child);
  }
}
