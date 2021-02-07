import 'package:flutter/material.dart';
import './cancellable_dialog.dart';

class ConfirmDialog extends CancellableDialog<bool> {
    
	static const String okLabel = 'OK';

    final String title;

    final String content;
	
	final String confirmationLabel;

	final bool isCancellable;

    ConfirmDialog({ 
		@required title, @required content, @required confirmationLabel 
	}): this._(
		title: title, 
		content: content, 
		isCancellable: true,
		confirmationLabel: confirmationLabel
	);

	ConfirmDialog._({ this.title, this.content, this.isCancellable, this.confirmationLabel });

    ConfirmDialog.ok({ @required String title, @required String content }):
        this._(title: title, content: content, isCancellable: false, confirmationLabel: okLabel);

    Future<bool> show(BuildContext context) async {

        return await showDialog<bool>(
            context: context, 
            builder: (buildContext) => new AlertDialog(
                content: new Text(content),
                title: new Text(title),
                actions: [
					if (isCancellable)
						buildCancelBtn(context, false),
					RaisedButton(
						child: new Text(confirmationLabel), 
                        	onPressed: () => Navigator.pop(buildContext, true)
					)
				]
            )
        );
    }
}
