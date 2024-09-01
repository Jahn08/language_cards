import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class AssuredFinder {
  AssuredFinder._();

  static Finder findOne(
          {Key? key,
          String? label,
          IconData? icon,
          Type? type,
          bool? shouldFind}) =>
      _find(
          key: key,
          expectSeveral: false,
          icon: icon,
          label: label,
          type: type,
          shouldFind: shouldFind);

  static Finder _find(
      {Key? key,
      String? label,
      IconData? icon,
      Type? type,
      bool? shouldFind,
      bool? expectSeveral}) {
    Finder finder;
    if (key != null)
      finder = find.byKey(key);
    else if (label != null && type != null)
      finder = find.widgetWithText(type, label);
    else if (label != null)
      finder = find.text(label);
    else if (icon != null)
      finder = find.byIcon(icon);
    else
      finder = find.byType(type!);

    expect(
        finder,
        (expectSeveral ?? false)
            ? matchSeveral(shouldFind: shouldFind)
            : matchOne(shouldFind: shouldFind));
    return finder;
  }

  static Finder findSeveral({String? label, Type? type, bool? shouldFind}) =>
      _find(
          expectSeveral: true,
          label: label,
          type: type,
          shouldFind: shouldFind);

  static Finder findFlatButtonByIcon(IconData icon, {bool? shouldFind}) {
    final flatBtnFinder = find.ancestor(
        of: find.byIcon(icon),
        matching: find.byWidgetPredicate((widget) => widget is TextButton));
    expect(flatBtnFinder, matchOne(shouldFind: shouldFind));

    return flatBtnFinder;
  }

  static Type typify<T>() => T;

  static Matcher matchOne({bool? shouldFind}) =>
      (shouldFind ?? false) ? findsOneWidget : findsNothing;

  static Matcher matchSeveral({bool? shouldFind}) =>
      (shouldFind ?? false) ? findsWidgets : findsNothing;
}
