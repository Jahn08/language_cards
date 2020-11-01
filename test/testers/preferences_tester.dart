import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_cards/src/data/preferences_provider.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/user_params.dart';
import '../utilities/randomiser.dart';

class PreferencesTester {

    PreferencesTester._();

    static resetSharedPreferences() => SharedPreferences.setMockInitialValues({});

    static Future<UserParams> saveRandomUserParams() async {
        resetSharedPreferences();
        
        final params = new UserParams();
        params.interfaceLang = Randomiser.nextElement(Language.values);
        params.theme = Randomiser.nextElement(AppTheme.values);
        params.studyParams.cardSide = Randomiser.nextElement(CardSide.values);
        
        await PreferencesProvider.save(params);

        return params;
    }
}
