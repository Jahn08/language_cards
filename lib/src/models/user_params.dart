import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'language.dart';
import 'presentable_enum.dart';

enum AppTheme {

    light, 

    dark
}

class CardSide extends PresentableEnum {

	static const CardSide front = CardSide._(0);

    static const CardSide back = CardSide._(1);

    static const CardSide random = CardSide._(2);

	static List<CardSide> get values => [front, back, random];

	const CardSide._(int index): super(index);

	@override
	String present(AppLocalizations locale) =>
		this == front ? locale.cardSideFrontName: 
			(this == back ? locale.cardSideBackName: locale.cardSideRandomName);
}

class StudyDirection extends PresentableEnum {
	
	static const StudyDirection forward = StudyDirection._(0);

    static const StudyDirection backward = StudyDirection._(1);

    static const StudyDirection random = StudyDirection._(2);

	static List<StudyDirection> get values => [forward, backward, random];

	const StudyDirection._(int index): super(index);

	@override
	String present(AppLocalizations locale) =>
		this == forward ? locale.cardStudyDirectionForwardName: 
			(this == backward ? locale.cardStudyDirectionBackwardName: 
				locale.cardStudyDirectionRandomName);
}

class StudyParams {
    static const _defaultCardSide = CardSide.front;
    static const _defaultDirection = StudyDirection.forward;

    static const _directionParam = 'direction';
    static const _cardSideParam = 'cardSide';

    StudyDirection _direction;
    StudyDirection get direction => _direction;
    set direction(StudyDirection value) => _direction = value ?? _defaultDirection;

    CardSide _cardSide;
    CardSide get cardSide => _cardSide;
    set cardSide(CardSide value) => _cardSide = value ?? _defaultCardSide;

    StudyParams([Map<String, dynamic> jsonMap]) {
        jsonMap = jsonMap ?? {};

        final directionIndex = jsonMap[_directionParam] as int;
        _direction = directionIndex == null ? _defaultDirection:
            StudyDirection.values[directionIndex]; 

        final cardSideIndex = jsonMap[_cardSideParam] as int;
        _cardSide = cardSideIndex == null ? _defaultCardSide: 
            CardSide.values[cardSideIndex];
    }

    Map<String, dynamic> toMap() => {
        _directionParam: _direction.index,
        _cardSideParam: _cardSide.index
    };
}

class UserParams {
    static const _defaultLanguage = Language.english;
    static const _defaultTheme = AppTheme.light;

    static const _interfaceLangParam = 'interfaceLang';
    static const _themeParam = 'theme';
    static const _studyParamsParam = 'studyParams';

	static const _ruLocale = Locale('ru');
	static const _enLocale = Locale('en');

    Language _interfaceLang;
    Language get interfaceLang => _interfaceLang;
    set interfaceLang(Language value) => _interfaceLang = value ?? _defaultLanguage;

	Locale getLocale() => _interfaceLang == Language.russian ? _ruLocale: _enLocale;

	static const interfaceLanguages = [Language.english, Language.russian];

    AppTheme _theme;
    AppTheme get theme => _theme;
    set theme(AppTheme value) => _theme = value ?? _defaultTheme;

    StudyParams _studyParams;
    StudyParams get studyParams => _studyParams;
    set studyParams(StudyParams value) => _studyParams = value ?? new StudyParams();

    UserParams([String json]) {
        final jsonMap = json == null ? {}: jsonDecode(json);

        final langIndex = jsonMap[_interfaceLangParam] as int;
		if (langIndex == null) {
			final supportedLangs = [_enLocale, _ruLocale].map((loc) => loc.languageCode).toList();
			final allLocs = WidgetsBinding.instance.window.locales;
			final firstLoc = allLocs.firstWhere((loc) => supportedLangs.contains(loc.languageCode), 
				orElse: () => allLocs.first);
			_interfaceLang = firstLoc.languageCode == _ruLocale.languageCode ? 
				Language.russian: Language.english;
		}
		else
			_interfaceLang = interfaceLanguages[langIndex];

        final themeIndex = jsonMap[_themeParam] as int;
        _theme = themeIndex == null ? _defaultTheme: AppTheme.values[themeIndex];

        _studyParams = new StudyParams(jsonMap[_studyParamsParam] as Map<String, dynamic>);
    }

    String toJson() => jsonEncode({
        _interfaceLangParam: _interfaceLang.index,
        _themeParam: _theme.index,
        _studyParamsParam: _studyParams.toMap()
    });
}
