import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_params.dart';

class PreferencesProvider {
    static const _userParamsKey = 'userParams';

    PreferencesProvider._();

    static Future<UserParams> fetch() async {
        final prefs = await SharedPreferences.getInstance();
        final userParamsValue = prefs.getString(_userParamsKey);

        return new UserParams(userParamsValue == null ? null: 
            json.decode(userParamsValue));
    }

    static Future<void> save(UserParams params) async {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString(_userParamsKey, json.encode(params.toJson()));
    }
}
