import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_params.dart';

class PreferencesProvider {
    static const _userParamsKey = 'userParams';

    PreferencesProvider._();

    static Future<UserParams> fetch() async {
        final prefs = await SharedPreferences.getInstance();
        return new UserParams(prefs.getString(_userParamsKey));
    }

    static Future<void> save(UserParams params) async {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString(_userParamsKey, params.toJson());
    }
}
