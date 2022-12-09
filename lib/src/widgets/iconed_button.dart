import 'package:flutter/material.dart';

class IconedButton extends StatelessWidget {

	final String label;

	final Icon icon;

	final void Function() onPressed;

	const IconedButton({ @required this.label, @required this.icon, @required this.onPressed });

	@override
	Widget build(BuildContext context) {
		return new InkWell(
			onTap: onPressed,
			child: Column(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				mainAxisSize: MainAxisSize.min,
				children: <Widget>[icon, new Text(label)]
        	)
      	);
	}
}
