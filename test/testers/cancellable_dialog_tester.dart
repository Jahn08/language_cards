import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utilities/widget_assistant.dart';
import 'dialog_tester.dart';

class CancellableDialogTester extends DialogTester {
  @protected
  final WidgetTester tester;

  const CancellableDialogTester(this.tester);

  Future<void> assureCancellingDialog() async {
    await CancellableDialogTester.cancelDialog(tester);

    DialogTester.assureDialog(shouldFind: false);
  }

  static Future<void> cancelDialog(WidgetTester tester) =>
      new WidgetAssistant(tester).pressButtonDirectlyByLabel('Cancel');
}
