import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/utilities/string_ext.dart';
import '../../utilities/randomiser.dart';

void main() {
  test('Returns true when a string is either empty or null', () {
    expect(isNullOrEmpty(''), true);
    expect(isNullOrEmpty(null), true);
  });

  test('Returns false when a string is neither empty nor null', () {
    expect(isNullOrEmpty(Randomiser.nextString()), false);
  });

  test('Returns a passed argument instead of an empty or null string', () {
    final defaultString = Randomiser.nextString();
    expect(getValueOrDefault('', defaultString), defaultString);
    expect(getValueOrDefault(null, defaultString), defaultString);
  });

  test('Returns a string itself when it is neither empty nor null', () {
    final defaultString = Randomiser.nextString();
    final expectedString = Randomiser.nextString();
    expect(getValueOrDefault(expectedString, defaultString), expectedString);
  });

  test('Splits a string into several by the @ symbol', () {
    final expectedStrings = <String>{
      Randomiser.nextString(),
      Randomiser.nextString(),
      Randomiser.nextString()
    };
    final actualStrings = splitLocalizedText(expectedStrings.join('@'));
    expect(actualStrings.length, expectedStrings.length);
    expect(actualStrings.every((s) => expectedStrings.contains(s)), true);
  });
}
