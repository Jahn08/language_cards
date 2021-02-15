import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import './loader.dart';
import '../dialogs/confirm_dialog.dart';
import '../models/language.dart';
import '../utilities/speaker.dart';

class SpeakerButton extends StatelessWidget {

	final Language lang;

	final Function(ISpeaker speaker) onPressed;

	final ISpeaker defaultSpeaker;

	SpeakerButton(this.lang, this.onPressed, { this.defaultSpeaker });

	@override
	Widget build(BuildContext context) =>
		defaultSpeaker == null ? 
			new FutureLoader(Speaker.getSpeaker(lang), (speaker) => _buildButton(context, speaker)): 
			_buildButton(context, defaultSpeaker);

	Widget _buildButton(BuildContext context, ISpeaker speaker) {
		if (speaker == null) {
			final locale = AppLocalizations.of(context);
			new ConfirmDialog.ok(
				title: locale.speakerButtonUnaivailableTTSDialogTitle,
				content: locale.speakerButtonUnaivailableTTSDialogContent(lang.toString())
			).show(context);
		}
			
		return IconButton(
			icon: new Icon(Icons.textsms_outlined),
			onPressed: speaker == null ? null: () => onPressed(speaker)
		);
	}
}
