import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../utilities/assured_finder.dart';
import '../utilities/localizator.dart';

class DialogTester {
  const DialogTester();

  Finder assureDialog({bool shouldFind}) =>
      AssuredFinder.findOne(type: AlertDialog, shouldFind: shouldFind);

  static Finder findConfirmationDialogBtn([String expectedLabel]) =>
      find.widgetWithText(
          ElevatedButton,
          expectedLabel ??
              Localizator.defaultLocalization.confirmDialogOkButtonLabel);

  static AlertDialog findConfirmationDialog(WidgetTester tester,
          [String expectedLabel]) =>
      tester.widget<AlertDialog>(find.ancestor(
          matching: find.byType(AlertDialog),
          of: findConfirmationDialogBtn(expectedLabel)));
}
