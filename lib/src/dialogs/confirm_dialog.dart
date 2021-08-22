import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'cancellable_dialog.dart';

class ConfirmDialog extends CancellableDialog<bool> {

    final String title;

    final String content;
	
	final String confirmationLabel;

	final bool isCancellable;

    ConfirmDialog({ 
		@required String title, @required String content, @required String confirmationLabel 
	}): this._(
		title: title, 
		content: content, 
		isCancellable: true,
		confirmationLabel: confirmationLabel
	);

	ConfirmDialog._({ this.title, this.content, this.isCancellable, this.confirmationLabel });

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
						buildCancelBtn(context, false),
					ElevatedButton(
						child: new Text(confirmationLabel ?? 
							AppLocalizations.of(context).confirmDialogOkButtonLabel), 
						onPressed: () => Navigator.pop(buildContext, true)
					)
				]
            )
        );
}
