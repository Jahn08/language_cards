import 'package:flutter_tts/flutter_tts.dart';
import '../models/language.dart';

abstract class ISpeaker {
  Future<void> speak(String text);
}

class Speaker implements ISpeaker {
  static Speaker? _instance;

  Language? _lang;

  final FlutterTts _tts;

  Speaker._() : _tts = new FlutterTts();

  Future<bool> _setLanguage(Language? newLang) async {
    if (newLang == _lang) return true;
    if (newLang == null) return false;

    final langStr = _stringifyLanguage(newLang);
    if (!(await _tts.isLanguageAvailable(langStr) as bool)) return false;

    await _tts.setLanguage(langStr);
    _lang = newLang;

    return true;
  }

  String _stringifyLanguage(Language lang) {
    switch (lang) {
      case Language.english:
        return 'en-GB';
      case Language.spanish:
        return 'es-ES';
      case Language.russian:
        return 'ru-RU';
      case Language.german:
        return 'de-DE';
      case Language.french:
        return 'fr-FR';
      case Language.italian:
        return 'it-IT';
      default:
        throw new Exception('Language $lang is not found');
    }
  }

  @override
  Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  static Future<ISpeaker?> getSpeaker(Language? lang) async {
    if (lang == null) return null;

    _instance ??= new Speaker._();

    if (!(await _instance!._setLanguage(lang))) return null;

    return _instance;
  }
}
