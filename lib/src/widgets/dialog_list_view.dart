import 'package:flutter/material.dart';

class DialogListView extends StatelessWidget {
	
	final Widget title;

	final List<Widget> children;

	DialogListView({ this.title, this.children });

	@override
	Widget build(BuildContext context) => 
		new AlertDialog(
			title: title == null ? null: 
				(title is SimpleDialogOption ? title: new SimpleDialogOption(child: title)),
			content: new Container(
				child: new Scrollbar(
					isAlwaysShown: true,
					child: new SingleChildScrollView(
						child: new Column(
							mainAxisSize: MainAxisSize.min,
							children: children
						)
					)
				)
			)
		);
}
