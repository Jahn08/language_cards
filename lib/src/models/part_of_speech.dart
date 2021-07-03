import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'presentable_enum.dart';

class PartOfSpeech extends PresentableEnum {

	static const adjective = const PartOfSpeech._(0, ['adjective', 'adj']);
	static const adverb = const PartOfSpeech._(1, ['adverb', 'adv']);
	static const collocation = const PartOfSpeech._(2, ['collocation']);
	static const conjunction = const PartOfSpeech._(3, ['conjunction', 'conj']);
	static const idiom = const PartOfSpeech._(4, ['idiom']);
	static const interjection = const PartOfSpeech._(5, ['interjection', 'excl']);
	static const noun = const PartOfSpeech._(6, ['noun', 'n']);
	static const participle = const PartOfSpeech._(7, ['participle']);
	static const preposition = const PartOfSpeech._(8, ['preposition', 'prep']);
	static const pronoun = const PartOfSpeech._(9, ['pronoun', 'pron']);
	static const verb = const PartOfSpeech._(10, ['verb', 'v']);
	static const numeral = const PartOfSpeech._(11, ['numeral', 'num']);
	static const determiner = const PartOfSpeech._(12, ['determiner', 'det']);
	static const exclamation = const PartOfSpeech._(13, ['exclamation', 'e']);
	static const prefix = const PartOfSpeech._(14, ['prefix', 'pref']);
	static const suffix = const PartOfSpeech._(15, ['suffix', 's']);
	static const abbreviation = const PartOfSpeech._(16, ['abbreviation', 'ab']);

	final List<String> valueList;

	const PartOfSpeech._(int index, this.valueList): super(index);

	static PartOfSpeech retrieve(String value) => 
		values.firstWhere((p) => p.valueList.contains(value), orElse: () => null);

	static List<PartOfSpeech> get values => [adjective, adverb, collocation,
		conjunction, idiom, interjection, noun, participle, preposition, pronoun, verb]; 

	@override
	String present(AppLocalizations locale) {
		if (this == adjective)
			return locale.partOfSpeechAdjectiveName;
		else if (this == adverb)
			return locale.partOfSpeechAdverbName;
		else if (this == conjunction)
			return locale.partOfSpeechConjunctionName;
		else if (this == idiom)
			return locale.partOfSpeechIdiomName;
		else if (this == interjection)
			return locale.partOfSpeechInterjectionName;
		else if (this == noun)
			return locale.partOfSpeechNounName;
		else if (this == participle)
			return locale.partOfSpeechParticipleName;
		else if (this == preposition)
			return locale.partOfSpeechPrepositionName;
		else if (this == pronoun)
			return locale.partOfSpeechPronounName;
		else if (this == verb)
			return locale.partOfSpeechVerbName;
		else if (this == determiner)
			return locale.partOfSpeechDeterminerName;
		else if (this == numeral)
			return locale.partOfSpeechNumeralName;
		else if (this == exclamation)
			return locale.partOfSpeechExclamationName;
		else if (this == abbreviation)
			return locale.partOfSpeechAbbreviationName;
		else if (this == prefix)
			return locale.partOfSpeechPrefixName;
		else if (this == suffix)
			return locale.partOfSpeechSuffixName;
	
		return locale.partOfSpeechCollocationName;
	}
}
