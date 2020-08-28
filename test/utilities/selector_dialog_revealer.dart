import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:language_cards/src/dialogs/selector_dialog.dart';
import './randomiser.dart';
import './test_root_widget.dart';

class SelectorDialogRevealer {
    SelectorDialogRevealer._();

    static Future<void> showDialog<T>(WidgetTester tester, List<T> items, { 
        @required SelectorDialog Function(BuildContext) builder, 
        Function(T) onDialogClose 
    }) async {
        BuildContext context;
        final dialogBtnKey = new Key(Randomiser.buildRandomString());
        await tester.pumpWidget(TestRootWidget.buildAsAppHome(
            onBuilding: (inContext) => context = inContext,
            child: new RaisedButton(
                key: dialogBtnKey,
                onPressed: () async {
                    final outcome = await builder(context).show(items);
                    onDialogClose?.call(outcome);
                })
            )
        );

        final foundDialogBtn = find.byKey(dialogBtnKey);
        expect(foundDialogBtn, findsOneWidget);
            
        await tester.tap(foundDialogBtn);
        await tester.pump(new Duration(milliseconds: 200));
    }
}
