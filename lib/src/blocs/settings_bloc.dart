enum AppLanguage {
    english,

    russian
}

enum AppTheme {
    light,

    dark
}

class SettingsBloc {
    AppTheme theme;
    AppLanguage language;

    SettingsBloc({this.theme, this.language});
}
