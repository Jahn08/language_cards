import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'presentable_enum.dart';

class Language extends PresentableEnum {
	
	static const Language english = Language._(0);

    static const Language russian = Language._(1);

    static const Language german = Language._(2);

    static const Language french = Language._(3);

    static const Language italian = Language._(4);

    static const Language spanish = Language._(5);

	static const values = [english, russian, german, french, italian, spanish];

	const Language._(int index): super(index);

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
