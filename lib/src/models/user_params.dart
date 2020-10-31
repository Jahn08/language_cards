import 'dart:convert';
import './language.dart';

enum AppTheme {
    light, 

    dark
}

enum CardSide {
    text,

    translation,

    random,

    openText
}

class StudyParams {
    static const _defaultBool = false;
    static const _defaultCardSide = CardSide.text;

    static const _isBackwardDirectionParam = 'isBackwardDirection';
    static const _cardSideParam = 'cardSide';

    bool _isBackwardDirection;
    bool get isBackwardDirection => _isBackwardDirection;
    set isBackwardDirection(bool value) => _isBackwardDirection = value ?? _defaultBool;

    CardSide _cardSide;
    CardSide get cardSide => _cardSide;
    set cardSide(CardSide value) => _cardSide = value ?? _defaultCardSide;

    StudyParams([Map<String, dynamic> jsonMap]) {
        jsonMap = jsonMap ?? {};

        _isBackwardDirection = jsonMap[_isBackwardDirectionParam] ?? _defaultBool; 

        final cardSideIndex = jsonMap[_cardSideParam];
        _cardSide = cardSideIndex == null ? _defaultCardSide: 
            CardSide.values[cardSideIndex];
    }

    Map<String, dynamic> toMap() => {
        _isBackwardDirectionParam: _isBackwardDirection,
        _cardSideParam: _cardSide.index
    };
}

class UserParams {
    static const _defaultLanguage = Language.english;
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
