import 'dart:collection';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'presentable_enum.dart';

class PartOfSpeech extends PresentableEnum {
  static const adjective = PartOfSpeech._(0, ['adjective', 'adj']);
  static const adverb = PartOfSpeech._(1, ['adverb', 'adv']);
  static const collocation = PartOfSpeech._(2, ['collocation']);
  static const conjunction = PartOfSpeech._(3, ['conjunction', 'conj']);
  static const idiom = PartOfSpeech._(4, ['idiom']);
  static const interjection = PartOfSpeech._(5, ['interjection', 'e']);
  static const noun = PartOfSpeech._(6, ['noun', 'n']);
  static const participle = PartOfSpeech._(7, ['participle']);
  static const preposition = PartOfSpeech._(8, ['preposition', 'prep']);
  static const pronoun = PartOfSpeech._(9, ['pronoun', 'pron']);
  static const verb = PartOfSpeech._(10, ['verb', 'v']);
  static const numeral = PartOfSpeech._(11, ['numeral', 'num']);
  static const determiner = PartOfSpeech._(12, ['determiner', 'det']);
  static const prefix = PartOfSpeech._(13, ['prefix', 'pref']);
  static const suffix = PartOfSpeech._(14, ['suffix', 's']);
  static const abbreviation = PartOfSpeech._(15, ['abbreviation', 'ab']);

  final List<String> valueList;

  const PartOfSpeech._(super.index, this.valueList);

  static PartOfSpeech retrieve(String? value) => value == null
      ? collocation
      : values.firstWhere((p) => p.valueList.contains(value),
          orElse: () => collocation);

  static HashSet<PartOfSpeech> get values => new HashSet.from([
        adjective,
        adverb,
        collocation,
        conjunction,
        idiom,
        interjection,
        noun,
        participle,
        preposition,
        pronoun,
        verb
      ]);

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
    else if (this == abbreviation)
      return locale.partOfSpeechAbbreviationName;
    else if (this == prefix)
      return locale.partOfSpeechPrefixName;
    else if (this == suffix) return locale.partOfSpeechSuffixName;

    return locale.partOfSpeechCollocationName;
  }

  @override
  String toString() => valueList.first;
}
