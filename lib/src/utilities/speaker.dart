import 'package:flutter_tts/flutter_tts.dart';
import '../models/language.dart';

abstract class ISpeaker {

	Future<void> speak(String text);
}

class Speaker implements ISpeaker {

	static Speaker _instance;

	Language _lang;

	final FlutterTts _tts;

	Speaker._(): _tts = new FlutterTts();

	Future<bool> _setLanguage(Language newLang) async {
		if (newLang == _lang)
			return true;

		final langStr = _stringifyLanguage(newLang);
		if (!await _tts.isLanguageAvailable(langStr))
			return false;

		await _tts.setLanguage(langStr);
		_lang = newLang;

		return true;
	}

	String _stringifyLanguage(Language lang) {
		if (lang == Language.english)
			return 'en-US';

        return lang == Language.russian ? 'ru-RU': null;
	}

	Future<void> speak(String text) async {
		await _tts.speak(text);
	}

	static Future<ISpeaker> getSpeaker(Language lang) async {
		if (_instance == null)
			_instance = new Speaker._();

		if (!(await _instance._setLanguage(lang)))
			return null;

		return _instance;
	}
}
