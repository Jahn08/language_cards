import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'presentable_enum.dart';

class PartOfSpeech extends PresentableEnum {
    
	static final adjective = new PartOfSpeech._(0, 'adjective');
	static final adverb = new PartOfSpeech._(1, 'adverb');
	static final collocation = new PartOfSpeech._(2, 'collocation');
	static final conjunction = new PartOfSpeech._(3, 'conjunction');
	static final idiom = new PartOfSpeech._(4, 'idiom');
	static final interjection = new PartOfSpeech._(5, 'interjection');
	static final noun = new PartOfSpeech._(6, 'noun');
	static final participle = new PartOfSpeech._(7, 'participle');
	static final preposition = new PartOfSpeech._(8, 'preposition');
	static final pronoun = new PartOfSpeech._(9, 'pronoun');
	static final verb = new PartOfSpeech._(10, 'verb');

	final String value;

	PartOfSpeech._(int index, this.value): super(index);

	static PartOfSpeech retrieve(String value) => 
		values.firstWhere((p) => p.value == value, orElse: () => null);

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
	
		return locale.partOfSpeechCollocationName;
	}
}
