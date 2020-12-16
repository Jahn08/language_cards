import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import './randomiser.dart';
import '../mocks/root_widget_mock.dart';
import './widget_assistant.dart';

class DialogOpener {

    DialogOpener._();

    static Future<void> showDialog<TResult>(WidgetTester tester, {
        @required Future<TResult> Function(BuildContext) dialogExposer,
        @required void Function(TResult) onDialogClose
    }) async {
        BuildContext context;
        final dialogBtnKey = new Key(Randomiser.nextString());
        await tester.pumpWidget(RootWidgetMock.buildAsAppHome(
            onBuilding: (inContext) => context = inContext,
            child: new RaisedButton(
                key: dialogBtnKey,
                onPressed: () async {
                    final outcome = await dialogExposer(context);
                    onDialogClose?.call(outcome);
                })
            )
        );

        final foundDialogBtn = find.byKey(dialogBtnKey);
        expect(foundDialogBtn, findsOneWidget);
            
        await new WidgetAssistant(tester).tapWidget(foundDialogBtn);
    }
}
