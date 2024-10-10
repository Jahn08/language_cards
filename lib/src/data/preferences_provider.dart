import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_params.dart';

class PreferencesProvider {
  static const _userParamsKey = 'userParams';

  static UserParams? _paramsCache;

  PreferencesProvider._();

  static Future<UserParams> fetch() async {
    if (_paramsCache == null) {
      final prefs = await SharedPreferences.getInstance();
      _paramsCache = new UserParams(prefs.getString(_userParamsKey));
    }

    return _paramsCache!;
  }

  static Future<void> save(UserParams params) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userParamsKey, params.toJson());
    _paramsCache = null;
  }
}
