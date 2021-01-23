import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/utilities/speaker.dart';

class SpeakerMock implements ISpeaker {

	final bool Function(Language) onSetLanguage;

	final void Function(String) onSpeak;

	SpeakerMock({ this.onSetLanguage, this.onSpeak });

	@override
	Future<bool> setLanguage(Language newLang) {
		final outcome = onSetLanguage?.call(newLang);
		return Future.value(outcome ?? true);
	}

	@override
	Future<void> speak(String text) {
		speak?.call(text);
		return Future.value();
	}
}
