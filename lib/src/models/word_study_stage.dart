import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WordStudyStage {
  static const int unknown = 0;

  static const int recognisedOnce = 25;

  static const int familiar = 50;

  static const int wellKnown = 75;

  static const int learned = 100;

  static const values = [unknown, recognisedOnce, familiar, wellKnown, learned];

  static String _getFamiliarStageName(AppLocalizations locale) =>
      locale.wordStudyStageFamiliarStageName;

  static String _getWellKnownStageName(AppLocalizations locale) =>
      locale.wordStudyStageWellKnownStageName;

  static String _getLearnedStageName(AppLocalizations locale) =>
      locale.wordStudyStageLearnedStageName;

  static String _getNewStageName(AppLocalizations locale) =>
      locale.wordStudyStageNewStageName;

  static int nextStage(int stage) {
    if (stage == learned) return learned;

    return WordStudyStage.values
        .firstWhere((v) => v > stage, orElse: () => learned);
  }

  static String stringify(int stage, AppLocalizations locale) {
    switch (stage) {
      case recognisedOnce:
      case familiar:
        return _getFamiliarStageName(locale);
      case wellKnown:
        return _getWellKnownStageName(locale);
      case learned:
        return _getLearnedStageName(locale);
      default:
        return _getNewStageName(locale);
    }
  }

  static List<int>? fromString(String name, AppLocalizations locale) {
    if (name == _getFamiliarStageName(locale))
      return [recognisedOnce, familiar];
    else if (name == _getWellKnownStageName(locale))
      return [wellKnown];
    else if (name == _getLearnedStageName(locale))
      return [learned];
    else if (name == _getNewStageName(locale)) return [unknown];

    return null;
  }
}
