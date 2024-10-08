import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/user_params.dart';
import 'package:language_cards/src/data/preferences_provider.dart';
import '../../testers/preferences_tester.dart';

void main() {
  testWidgets(
      'Loads empty user settings from the storage of shared preferences',
      (_) async {
    await PreferencesTester.saveDefaultUserParams();

    final userParams = await PreferencesProvider.fetch();
    expect(userParams.toJson(), new UserParams().toJson());
  });

  testWidgets(
      'Saves and loads user settings to the storage of shared preferences',
      (_) async {
    final expectedParams = await PreferencesTester.saveRandomUserParams();

    final expectedLang = expectedParams.interfaceLang;
    final expectedTheme = expectedParams.theme;
    final expectedCardSide = expectedParams.studyParams.cardSide;
    final expectedPackOrder = expectedParams.studyParams.packOrder;

    final userParams = await PreferencesProvider.fetch();
    expect(userParams.theme, expectedTheme);
    expect(userParams.interfaceLang, expectedLang);
    expect(userParams.studyParams.cardSide, expectedCardSide);
    expect(userParams.studyParams.packOrder, expectedPackOrder);
  });
}
