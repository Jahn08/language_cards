import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'outcome_dialog.dart';
import '../widgets/cancel_button.dart';

class ConfirmDialog extends OutcomeDialog<bool> {

    final String title;

    final String content;
	
	final String confirmationLabel;

	final bool isCancellable;

    const ConfirmDialog({ 
		@required String title, @required String content, @required String confirmationLabel 
	}): this._(
		title: title, 
		content: content, 
		isCancellable: true,
		confirmationLabel: confirmationLabel
	);

	const ConfirmDialog._({ this.title, this.content, this.isCancellable, this.confirmationLabel }): 
		super();

    ConfirmDialog.ok({ @required String title, @required String content }):
        this._(title: title, content: content, isCancellable: false);

    Future<bool> show(BuildContext context) => 
		showDialog<bool>(
            context: context, 
            builder: (buildContext) => new AlertDialog(
                content: new Text(content),
                title: new Text(title),
                actions: [
					if (isCancellable)
						new CancelButton(() => returnResult(context, false)),
					ElevatedButton(
						child: new Text(confirmationLabel ?? 
							AppLocalizations.of(context).confirmDialogOkButtonLabel), 
						onPressed: () => Navigator.pop(buildContext, true)
					)
				]
            )
        );
}
