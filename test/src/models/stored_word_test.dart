import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/stored_word.dart';

void main() {
  test('Creates a word and normalizes its text if necessary', () {
    final wordToNormalize = new StoredWord('café');
    expect(wordToNormalize.text, 'café');
    expect(wordToNormalize.normalText, 'cafe');

    final normalizedWord = new StoredWord('café', normalText: 'café');
    expect(normalizedWord.normalText, 'café');

    final word = new StoredWord('coffee');
    expect(word.normalText, 'coffee');
  });
}
