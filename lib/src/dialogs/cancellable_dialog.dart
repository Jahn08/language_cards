import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'outcome_dialog.dart';

abstract class CancellableDialog<TResult> extends OutcomeDialog<TResult> {

    @protected
    Widget buildCancelBtn(BuildContext context, [TResult result]) {
		return new ElevatedButton(
			onPressed: () => returnResult(context, result),
			child: new Text(
				AppLocalizations.of(context).cancellableDialogCancellationButtonLabel
			),
			style: ElevatedButton.styleFrom(primary: Colors.deepOrange[300])
		);
	} 
}
