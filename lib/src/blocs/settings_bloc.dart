import 'dart:collection';
import 'package:flutter/material.dart';
import '../models/user_params.dart';
import '../data/preferences_provider.dart';

typedef OnSaveListener = void Function(UserParams params);

class SettingsBloc {
  final _listeners = new HashSet<OnSaveListener>();

  UserParams _params;

  SettingsBloc._();

  Future<UserParams> get userParams async {
    _params ??= await PreferencesProvider.fetch();
    return new UserParams(_params.toJson());
  }

  Future<void> save(UserParams params) async {
    await PreferencesProvider.save(params);
    _params = null;

    _listeners.forEach((listener) => listener?.call(params));
  }

  void addOnSaveListener(OnSaveListener listener) => _listeners.add(listener);

  bool removeOnSaveListener(OnSaveListener listener) =>
      _listeners.remove(listener);
}

class SettingsBlocProvider extends InheritedWidget {
  final SettingsBloc _bloc;

  SettingsBlocProvider({Key key, @required Widget child})
      : _bloc = new SettingsBloc._(),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(_) => true;

  static SettingsBloc of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<SettingsBlocProvider>()
        ._bloc;
  }
}
