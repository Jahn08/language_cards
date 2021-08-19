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

	const SpeakerButton(this.lang, this.onPressed, { this.defaultSpeaker });

	@override
	Widget build(BuildContext context) {
		final futureSpeaker = defaultSpeaker == null ? 
			Speaker.getSpeaker(lang): Future.value(defaultSpeaker);
		return new FutureLoader(futureSpeaker, (ISpeaker speaker) {
			if (speaker == null) {
				final locale = AppLocalizations.of(context);
				new ConfirmDialog.ok(
					title: locale.speakerButtonUnaivailableTTSDialogTitle,
					content: locale.speakerButtonUnaivailableTTSDialogContent(lang.toString())
				).show(context);
			}
				
			return IconButton(
				icon: const Icon(Icons.textsms_outlined),
				onPressed: speaker == null ? null: () => onPressed(speaker)
			);
		});
	}
}
