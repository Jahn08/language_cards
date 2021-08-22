import 'package:language_cards/src/utilities/speaker.dart';

class SpeakerMock implements ISpeaker {

	final void Function(String) onSpeak;

	const SpeakerMock({ this.onSpeak });

	@override
	Future<void> speak(String text) {
		onSpeak?.call(text);
		return Future.value();
	}
}
