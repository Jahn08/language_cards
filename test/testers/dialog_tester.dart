import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utilities/assured_finder.dart';
import '../utilities/localizator.dart';

class DialogTester {

	Finder assureDialog({ bool shouldFind }) => 
		AssuredFinder.findOne(type: SimpleDialog, shouldFind: shouldFind);

	static Finder findConfirmationDialog([String expectedLabel]) => 
		find.widgetWithText(RaisedButton, 
			expectedLabel ?? Localizator.defaultLocalization.confirmDialogOkButtonLabel);
}
