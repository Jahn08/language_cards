import 'package:flutter/widgets.dart';
import '../utilities/styler.dart';

class UnderlinedContainer extends StatelessWidget {

	final Widget child;

	UnderlinedContainer(this.child);

	@override
	Widget build(BuildContext context) {
		return new Container(
			decoration: new BoxDecoration(
				border: new Border(
					bottom: new BorderSide(
						style: BorderStyle.solid,
						width: 1.0,
						color: new Styler(context).dividerColor
					)
				)
			),
			child: child
		);
	}
}
