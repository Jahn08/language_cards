import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_cards/src/data/preferences_provider.dart';
import 'package:language_cards/src/models/user_params.dart';
import '../utilities/randomiser.dart';

class PreferencesTester {
  PreferencesTester._();

  static void resetSharedPreferences() =>
      SharedPreferences.setMockInitialValues({});

  static Future<UserParams> saveRandomUserParams() async {
    final params = new UserParams();
    params.interfaceLang =
        Randomiser.nextElement(UserParams.interfaceLanguages);
    params.theme = Randomiser.nextElement(AppTheme.values);
    params.studyParams.packOrder = Randomiser.nextElement(PackOrder.values);
    params.studyParams.cardSide = Randomiser.nextElement(CardSide.values);
    params.studyParams.direction =
        Randomiser.nextElement(StudyDirection.values);
    params.studyParams.showStudyDate = Randomiser.nextInt().isEven;

    await saveParams(params);

    return params;
  }

  static Future<void> saveParams(UserParams params) async {
    resetSharedPreferences();
    await PreferencesProvider.save(params);
  }

  static Future<UserParams> saveNonDefaultUserParams() async {
    final params = new UserParams();
    params.interfaceLang = _getFirstDistinctFrom(
        params.interfaceLang, UserParams.interfaceLanguages);
    params.theme = _getFirstDistinctFrom(params.theme, AppTheme.values);
    params.studyParams.packOrder =
        _getFirstDistinctFrom(params.studyParams.packOrder, PackOrder.values);
    params.studyParams.cardSide =
        _getFirstDistinctFrom(params.studyParams.cardSide, CardSide.values);
    params.studyParams.direction = _getFirstDistinctFrom(
        params.studyParams.direction, StudyDirection.values);
    params.studyParams.showStudyDate = !params.studyParams.showStudyDate;

    await saveParams(params);

    return params;
  }

  static T _getFirstDistinctFrom<T>(T value, List<T> values) =>
      values.firstWhere((v) => v != value);
}
