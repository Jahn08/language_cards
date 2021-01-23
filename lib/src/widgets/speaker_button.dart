import 'package:flutter/material.dart';
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
		if (speaker == null)
			ConfirmDialog.buildOkDialog(
				title: 'Text to Speech Is Unavailable', 
				content: 'The language $lang is absent. ' +
					'Try installing it in the settings of your device'
			).show(context);

		return IconButton(
			icon: new Icon(Icons.textsms_outlined),
			onPressed: speaker == null ? null: () => onPressed(speaker)
		);
	}
}
