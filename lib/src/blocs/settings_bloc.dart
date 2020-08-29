import 'package:flutter/material.dart';

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

class SettingsBlocProvider extends InheritedWidget {
    final SettingsBloc _bloc;

    SettingsBlocProvider({ Key key, @required Widget child }):
        _bloc = new SettingsBloc(language: AppLanguage.english, theme: AppTheme.dark),
        super(key: key, child: child);

    @override
    bool updateShouldNotify(_) => true;

    static SettingsBloc of(BuildContext context) {
        return context.dependOnInheritedWidgetOfExactType<SettingsBlocProvider>()._bloc;
    }
}
