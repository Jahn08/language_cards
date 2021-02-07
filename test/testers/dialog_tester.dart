import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/dialogs/confirm_dialog.dart';
import '../utilities/assured_finder.dart';

class DialogTester {

	Finder assureDialog({ bool shouldFind }) => 
		AssuredFinder.findOne(type: SimpleDialog, shouldFind: shouldFind);

	static Finder findConfirmationDialog([String expectedLabel = ConfirmDialog.okLabel]) => 
		find.widgetWithText(RaisedButton, expectedLabel);
}
