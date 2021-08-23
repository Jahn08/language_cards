import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CancelButton extends StatelessWidget {

	final void Function() onPressed;

	const CancelButton(this.onPressed);

	@override
	Widget build(BuildContext context) =>
		new ElevatedButton(
			onPressed: onPressed,
			child: new Text(
				AppLocalizations.of(context).cancellableDialogCancellationButtonLabel
			),
			style: ElevatedButton.styleFrom(primary: Colors.deepOrange[300])
		);
}
