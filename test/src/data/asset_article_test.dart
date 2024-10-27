import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/article.dart';
import 'package:language_cards/src/models/part_of_speech.dart';
import '../../utilities/randomiser.dart';

void main() {
  test('Creates an asset article from empty and filled word maps', () {
    final emptyWord = <String, dynamic>{};
    final collocationWord = <String, dynamic>{"p": Randomiser.nextString()};
    
    final fullWordText = Randomiser.nextString();
    final fullWordTranscription = Randomiser.nextString();
    final fullWordTranslations = [Randomiser.nextString(), Randomiser.nextString()];
    final fullWord = <String, dynamic>{
      "t": fullWordText,
      "s": fullWordTranscription,
      "p": 'adv',
      "r": fullWordTranslations
    };
    final defaultText = Randomiser.nextString();
    final article = new AssetArticle(defaultText,
        List.from([emptyWord, fullWord, collocationWord]));
    
    final firstWord = article.words[0];
    expect(firstWord.text, defaultText);
    expect(firstWord.id, null);
    expect(firstWord.partOfSpeech, PartOfSpeech.collocation);
    expect(firstWord.transcription, '');
    expect(firstWord.translations.isEmpty, true);
    
    final secondWord = article.words[1];
    expect(secondWord.text, fullWordText);
    expect(secondWord.id, null);
    expect(secondWord.partOfSpeech, PartOfSpeech.adverb);
    expect(secondWord.transcription, fullWordTranscription);
    expect(const ListEquality().equals(secondWord.translations, fullWordTranslations), true);
    
    expect(article.words[2].partOfSpeech, PartOfSpeech.collocation);
  });

  test('Creates an empty asset article from a null word map', () {
    final article = new AssetArticle(Randomiser.nextString(), null);
    expect(article.words.isEmpty, true);
  });
}
