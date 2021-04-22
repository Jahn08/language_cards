import 'package:flutter_gen/gen_l10n/app_localizations.dart';

abstract class PresentableEnum {

	final int index;

	const PresentableEnum(this.index);

	String present(AppLocalizations locale);
	
	static Map<String, PresentableEnum> mapStringValues(
		Iterable<PresentableEnum> values, AppLocalizations locale
	) => new Map.fromIterable(values, key: (v) => v.present(locale), value: (v) => v);
}
