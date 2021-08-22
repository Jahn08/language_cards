import 'package:flutter/material.dart';

class ShrinkableSimpleDialogOption extends SimpleDialogOption {

	static final EdgeInsets _defaultPadding = const SimpleDialogOption().padding;

	ShrinkableSimpleDialogOption(Widget child, { bool isShrunk, void Function() onPressed }): 
		super(child: child, onPressed: onPressed, 
			padding: (isShrunk ?? false) ? EdgeInsets.zero : _defaultPadding);
}

class DialogListView extends StatelessWidget {

	static const _defaultAlertDialog = AlertDialog();

	final Widget title;

	final List<Widget> children;

	final List<Widget> buttons;

	final bool isShrunk;

	const DialogListView({ this.title, this.children, this.buttons, bool isShrunk }):
		isShrunk = isShrunk ?? false;

	@override
	Widget build(BuildContext context) =>
		new AlertDialog(
			actions: buttons,
			contentPadding: isShrunk ? EdgeInsets.zero: _defaultAlertDialog.contentPadding,
			titlePadding: isShrunk ? EdgeInsets.zero: _defaultAlertDialog.titlePadding,
			title: title == null ? null: (
				title is SimpleDialogOption ? title: 
					new ShrinkableSimpleDialogOption(title, isShrunk: isShrunk)
			),
			content: new SizedBox(
				width: double.maxFinite,
				child: new Scrollbar(
					isAlwaysShown: true,
					child: new _ScrollView(
						child: new Column(
							mainAxisSize: MainAxisSize.min,
							children: children
						),
						isShrunk: isShrunk
					)
				)
			)
		);
}

class _ScrollView extends StatelessWidget {

	final bool isShrunk;

	final Widget child;

	const _ScrollView({ @required this.child, @required this.isShrunk });

	@override
	Widget build(BuildContext context) =>
		isShrunk ? new SingleChildScrollView(child: child, padding: EdgeInsets.zero):
			new SingleChildScrollView(child: child);
}
