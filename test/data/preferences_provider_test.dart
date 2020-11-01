import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/user_params.dart';
import 'package:language_cards/src/data/preferences_provider.dart';
import '../testers/preferences_tester.dart';

void main() {

    test('Loads empty user settings from the storage of shared preferences', () async {
        PreferencesTester.resetSharedPreferences();

        final userParams = await PreferencesProvider.fetch();
        expect(userParams?.toJson(), new UserParams().toJson());
    });

    test('Saves and loads user settings to the storage of shared preferences', () async {
        final expectedParams = await PreferencesTester.saveRandomUserParams();

        final expectedLang = expectedParams.interfaceLang;
        final expectedTheme = expectedParams.theme;
        final expectedCardSide = expectedParams.studyParams.cardSide;
        
        final userParams = await PreferencesProvider.fetch();
        expect(userParams != null, true);
        expect(userParams.theme, expectedTheme);
        expect(userParams.interfaceLang, expectedLang);
        expect(userParams.studyParams?.cardSide, expectedCardSide);
    });
}
