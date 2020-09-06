import 'package:flutter/material.dart';
import '../models/language.dart';

export '../models/language.dart';

enum AppTheme {
    light,

    dark
}

class SettingsBloc {
    AppTheme theme;
    Language language;

    SettingsBloc({this.theme, this.language});
}

class SettingsBlocProvider extends InheritedWidget {
    final SettingsBloc _bloc;

    SettingsBlocProvider({ Key key, @required Widget child }):
        _bloc = new SettingsBloc(language: Language.english, theme: AppTheme.dark),
        super(key: key, child: child);

    @override
    bool updateShouldNotify(_) => true;

    static SettingsBloc of(BuildContext context) {
        return context.dependOnInheritedWidgetOfExactType<SettingsBlocProvider>()._bloc;
    }
}
