import 'package:flutter/material.dart';

const _zeroPadding = const EdgeInsets.all(0);

class ShrinkableSimpleDialogOption extends SimpleDialogOption {

	static final EdgeInsets _defaultPadding = new SimpleDialogOption().padding;

	ShrinkableSimpleDialogOption(Widget child, { bool isShrunk, void Function() onPressed }): 
		super(child: child, onPressed: onPressed, 
			padding: (isShrunk ?? false) ? _zeroPadding : _defaultPadding);
}

class DialogListView extends StatelessWidget {

	static const _defaultAlertDialog = const AlertDialog();

	final Widget title;

	final List<Widget> children;

	final List<Widget> buttons;

	final bool isShrunk;

	DialogListView({ this.title, this.children, this.buttons, bool isShrunk }):
		this.isShrunk = isShrunk ?? false;

	@override
	Widget build(BuildContext context) {
		
		return new AlertDialog(
			actions: this.buttons,
			contentPadding: isShrunk ? _zeroPadding: _defaultAlertDialog.contentPadding,
			titlePadding: isShrunk ? _zeroPadding: _defaultAlertDialog.titlePadding,
			title: title == null ? null: (
				title is SimpleDialogOption ? title: 
					new ShrinkableSimpleDialogOption(title, isShrunk: isShrunk)
			),
			content: new Container(
				width: double.maxFinite,
				child: new Scrollbar(
					isAlwaysShown: true,
					child: _buildScrollView(
						new Column(
							mainAxisSize: MainAxisSize.min,
							children: children
						)
					) 
				)
			)
		);
	}

	Widget _buildScrollView(Widget child) =>
		isShrunk ? new SingleChildScrollView(child: child, padding: _zeroPadding):
			new SingleChildScrollView(child: child);
}
