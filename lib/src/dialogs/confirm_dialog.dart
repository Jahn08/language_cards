import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'outcome_dialog.dart';
import '../widgets/cancel_button.dart';
import '../widgets/one_line_text.dart';

class ConfirmDialog extends OutcomeDialog<bool> {
  final String title;

  final String content;

  final String? confirmationLabel;

  final String? cancellationLabel;

  final bool isCancellable;

  const ConfirmDialog(
      {required String title,
      required String content,
      required String confirmationLabel,
      String? cancellationLabel})
      : this._(
            title: title,
            content: content,
            isCancellable: true,
            confirmationLabel: confirmationLabel,
            cancellationLabel: cancellationLabel);

  const ConfirmDialog._(
      {required this.title,
      required this.content,
      required this.isCancellable,
      this.confirmationLabel,
      this.cancellationLabel})
      : super();

  ConfirmDialog.ok({required String title, required String content})
      : this._(title: title, content: content, isCancellable: false);

  Future<bool?> show(BuildContext context) => showDialog<bool>(
      context: context,
      builder: (buildContext) => new AlertDialog(
              content: new Scrollbar(
                  thumbVisibility: true,
                  child: new SingleChildScrollView(child: new Text(content))),
              title: new OneLineText(title),
              actions: [
                if (isCancellable)
                  new CancelButton(
                      () => returnResult(context, false), cancellationLabel),
                ElevatedButton(
                    child: new Text(confirmationLabel ??
                        AppLocalizations.of(context)!
                            .confirmDialogOkButtonLabel),
                    onPressed: () => Navigator.pop(buildContext, true))
              ]));
}
