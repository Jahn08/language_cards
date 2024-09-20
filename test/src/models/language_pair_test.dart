import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/language.dart';

import '../../utilities/localizator.dart';

void main() {
  test(
      'Creates an empty pair if the languages are equal, or a non-empty one otherwise',
      () {
    final emptyLangPair = LanguagePair.empty();
    expect(emptyLangPair.isEmpty, true);
    expect(const LanguagePair(Language.french, Language.french).isEmpty, true);
    expect(const LanguagePair(Language.french, Language.german).isEmpty, false);
  });

  test('Considers pairs equal if their langauges are same', () {
    const firstPair = LanguagePair(Language.english, Language.french);
    const secondPair = LanguagePair(Language.english, Language.french);
    expect(firstPair, secondPair);
    expect(firstPair.hashCode, secondPair.hashCode);

    const thirdPair = LanguagePair(Language.french, Language.english);
    expect(firstPair == thirdPair, false);
  });

  test('Creates a pair from a map', () {
    expect(LanguagePair.fromMap({'from': 1, 'to': 3}),
        const LanguagePair(Language.russian, Language.french));
  });

  test('Creates a pair from a DB map', () {
    expect(LanguagePair.fromDbMap({'from_lang': 5, 'to_lang': 4}),
        const LanguagePair(Language.spanish, Language.italian));
  });

  test('Creates a map of properties of a pair', () {
    expect(
        mapEquals(
            const LanguagePair(Language.russian, Language.spanish).toMap(),
            {'from': 1, 'to': 5}),
        true);
  });

  test('Presents a pair as a string', () {
    expect(
        const LanguagePair(Language.spanish, Language.german)
            .present(Localizator.defaultLocalization),
        'Spanish - German');
  });
}
