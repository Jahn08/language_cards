import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utilities/widget_assistant.dart';

class CancellableDialogTester {

	static Future<void> assureCancellingDialog(WidgetTester tester) async {
		final assistant = new WidgetAssistant(tester);
        await assistant.pressButtonDirectlyByLabel('Cancel');

        expect(find.byType(SimpleDialog), findsNothing);
	}
}
