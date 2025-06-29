import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../widgets/empty_widget.dart';
import '../widgets/one_line_text.dart';

class LoaderDialog {
  LoaderDialog._();

  static Future<LoaderState<T>?> showAsync<T>(BuildContext context,
      Future<T> Function() processor, AppLocalizations locale) {
    return showDialog<LoaderState<T>>(
        barrierDismissible: false,
        context: context,
        builder: (dialogContext) {
          return new FutureBuilder<T>(
              future: processor(),
              builder: (buildingContext, snapshot) {
                if (snapshot.hasData || snapshot.hasError) {
                  WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                    Navigator.pop(
                        buildingContext,
                        snapshot.hasData
                            ? new LoaderState<T>(value: snapshot.data)
                            : new LoaderState<T>(error: snapshot.error));
                  });
                  return const EmptyWidget();
                }

                return new AlertDialog(
                    content: new Row(children: [
                  Expanded(child: new OneLineText(locale.loaderDialogLabel)),
                  const CircularProgressIndicator()
                ]));
              });
        });
  }
}

class LoaderState<T> {
  final T? value;

  final Object? error;

  LoaderState({this.value, this.error});
}
