import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/user_params.dart';
import 'package:language_cards/src/data/preferences_provider.dart';
import '../utilities/randomiser.dart';

void main() {

    test('Loads empty user settings from the storage of shared preferences', () async {
        SharedPreferences.setMockInitialValues({});

        final userParams = await PreferencesProvider.fetch();
        expect(userParams?.toJson(), new UserParams().toJson());
    });

    test('Saves and loads user settings to the storage of shared preferences', () async {
        SharedPreferences.setMockInitialValues({});

        final expectedLang = Randomiser.nextElement(Language.values);
        final expectedTheme = Randomiser.nextElement(AppTheme.values);
        final expectedCardSide = Randomiser.nextElement(CardSide.values);

        final params = new UserParams();
        params.interfaceLang = expectedLang;
        params.theme = expectedTheme;
        params.studyParams.cardSide = expectedCardSide;
        await PreferencesProvider.save(params);

        final userParams = await PreferencesProvider.fetch();
        expect(userParams != null, true);
        expect(userParams.theme, expectedTheme);
        expect(userParams.interfaceLang, expectedLang);
        expect(params.studyParams?.cardSide, expectedCardSide);
    });
}
