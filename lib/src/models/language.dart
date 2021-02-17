import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'presentable_enum.dart';

class Language extends PresentableEnum {
	
	static final Language english = new Language._(0);

    static final Language russian = new Language._(1);

	static List<Language> get values => [english, russian];

	Language._(int index): super(index);

	@override
	String present(AppLocalizations locale) =>
		this == russian ? locale.languageRussianName : locale.languageEnglishName; 
}
