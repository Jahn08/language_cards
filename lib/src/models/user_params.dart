import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'language.dart';
import 'presentable_enum.dart';

enum AppTheme {
    light, 

    dark
}

class CardSide extends PresentableEnum {

	static final CardSide front = new CardSide._(0);

    static final CardSide back = new CardSide._(1);

    static final CardSide random = new CardSide._(2);

	static List<CardSide> get values => [front, back, random];

	CardSide._(int index): super(index);

	@override
	String present(AppLocalizations locale) =>
		this == front ? locale.cardSideFrontName: 
			(this == back ? locale.cardSideBackName: locale.cardSideRandomName);
}

class StudyDirection extends PresentableEnum {
	
	static final StudyDirection forward = new StudyDirection._(0);

    static final StudyDirection backward = new StudyDirection._(1);

    static final StudyDirection random = new StudyDirection._(2);

	static List<StudyDirection> get values => [forward, backward, random];

	StudyDirection._(int index): super(index);

	@override
	String present(AppLocalizations locale) =>
		this == forward ? locale.cardStudyDirectionForwardName: 
			(this == backward ? locale.cardStudyDirectionBackwardName: 
				locale.cardStudyDirectionRandomName);
}

class StudyParams {
    static final _defaultCardSide = CardSide.front;
    static final _defaultDirection = StudyDirection.forward;

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

        final directionIndex = jsonMap[_directionParam];
        _direction = directionIndex == null ? _defaultDirection:
            StudyDirection.values[directionIndex]; 

        final cardSideIndex = jsonMap[_cardSideParam];
        _cardSide = cardSideIndex == null ? _defaultCardSide: 
            CardSide.values[cardSideIndex];
    }

    Map<String, dynamic> toMap() => {
        _directionParam: _direction.index,
        _cardSideParam: _cardSide.index
    };
}

class UserParams {
    static final _defaultLanguage = Language.english;
    static const _defaultTheme = AppTheme.light;

    static const _interfaceLangParam = 'interfaceLang';
    static const _themeParam = 'theme';
    static const _studyParamsParam = 'studyParams';

    Language _interfaceLang;
    Language get interfaceLang => _interfaceLang;
    set interfaceLang(Language value) => _interfaceLang = value ?? _defaultLanguage;

    AppTheme _theme;
    AppTheme get theme => _theme;
    set theme(AppTheme value) => _theme = value ?? _defaultTheme;

    StudyParams _studyParams;
    StudyParams get studyParams => _studyParams;
    set studyParams(StudyParams value) => _studyParams = value ?? new StudyParams();

    UserParams([String json]) {
        final jsonMap = json == null ? {}: jsonDecode(json);

        final langIndex = jsonMap[_interfaceLangParam];
        _interfaceLang = langIndex == null ? _defaultLanguage: Language.values[langIndex];

        final themeIndex = jsonMap[_themeParam];
        _theme = themeIndex == null ? _defaultTheme: AppTheme.values[themeIndex];

        _studyParams = new StudyParams(jsonMap[_studyParamsParam]);
    }

    String toJson() => jsonEncode({
        _interfaceLangParam: _interfaceLang.index,
        _themeParam: _theme.index,
        _studyParamsParam: _studyParams.toMap()
    });
}
