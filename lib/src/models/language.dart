import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'presentable_enum.dart';

class Language extends PresentableEnum {
  static const Language english = Language._(0);

  static const Language russian = Language._(1);

  static const Language german = Language._(2);

  static const Language french = Language._(3);

  static const Language italian = Language._(4);

  static const Language spanish = Language._(5);

  static const values = [english, russian, german, french, italian, spanish];

  const Language._(super.index);

  @override
  String present(AppLocalizations locale) {
    switch (this) {
      case Language.english:
        return locale.languageEnglishName;
      case Language.russian:
        return locale.languageRussianName;
      case Language.spanish:
        return locale.languageSpanishName;
      case Language.french:
        return locale.languageFrenchName;
      case Language.german:
        return locale.languageGermanName;
      case Language.italian:
        return locale.languageItalianName;
      default:
        return '';
    }
  }
}

class LanguagePair {
  static const _fromFieldName = 'from';
  static const _toFieldName = 'to';

  final Language from;

  final Language to;

  const LanguagePair(this.from, this.to);

  LanguagePair.empty() : this(Language.english, Language.english);

  LanguagePair.fromMap(Map<String, dynamic> map)
      : this(Language.values[map[_fromFieldName] as int],
            Language.values[map[_toFieldName] as int]);

  LanguagePair.fromDbMap(Map<String, dynamic> map)
      : this(Language.values[map[StoredPack.fromFieldName] as int],
            Language.values[map[StoredPack.toFieldName] as int]);

  Map<String, dynamic> toMap() =>
      {_fromFieldName: from.index, _toFieldName: to.index};

  String present(AppLocalizations locale) {
    return '${from.present(locale)} - ${to.present(locale)}';
  }

  bool get isEmpty => to == from;

  @override
  bool operator ==(Object o) =>
      o is LanguagePair && o.to == to && o.from == from;

  @override
  int get hashCode => Object.hash(to, from);
}
