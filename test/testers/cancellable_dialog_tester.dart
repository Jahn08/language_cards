import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utilities/widget_assistant.dart';
import 'dialog_tester.dart';

class CancellableDialogTester extends DialogTester {

	@protected
	final WidgetTester tester;
	
	CancellableDialogTester(this.tester);

	Future<void> assureCancellingDialog() async {
		final assistant = new WidgetAssistant(tester);
        await assistant.pressButtonDirectlyByLabel('Cancel');

		assureDialog(shouldFind: false);
	}
}
