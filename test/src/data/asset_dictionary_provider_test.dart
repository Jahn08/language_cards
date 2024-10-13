import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/asset_dictionary_provider.dart';
import 'package:language_cards/src/models/language.dart';
import '../../mocks/root_widget_mock.dart';
import '../../testers/word_dictionary_tester.dart';
import '../../utilities/randomiser.dart';

void main() {
  testWidgets('Gets the names of language pairs available for translation',
      (tester) async {
    await tester
        .pumpWidget(RootWidgetMock.buildAsAppHome(onBuilding: (context) async {
      final languages =
          await new AssetDictionaryProvider(context).getAcceptedLanguages();
      final expectedLangPairs = [
        WordDictionaryTester.buildLangPair(Language.english, Language.russian),
        WordDictionaryTester.buildLangPair(Language.russian, Language.english)
      ];
      expect(expectedLangPairs.every((p) => languages.contains(p)), true);
    }));
  });

  testWidgets('Shows that translation is possible for a given language pair',
      (tester) async {
    await tester
        .pumpWidget(RootWidgetMock.buildAsAppHome(onBuilding: (context) async {
      final langParam = WordDictionaryTester.buildLangPair(
          Language.english, Language.russian);
      expect(
          await new AssetDictionaryProvider(context)
              .isTranslationPossible(langParam),
          true);
    }));
  });

  testWidgets(
      'Shows that translation is not possible for a given language pair',
      (tester) async {
    await tester
        .pumpWidget(RootWidgetMock.buildAsAppHome(onBuilding: (context) async {
      final langParam =
          WordDictionaryTester.buildLangPair(Language.italian, Language.german);
      expect(
          await new AssetDictionaryProvider(context)
              .isTranslationPossible(langParam),
          false);
    }));
  });

  testWidgets('Retrieves an article for an existent word', (tester) async {
    await tester
        .pumpWidget(RootWidgetMock.buildAsAppHome(onBuilding: (context) async {
      const wordToLookUp = ' World ';
      final article = await new AssetDictionaryProvider(context).lookUp(
          WordDictionaryTester.buildLangPair(
              Language.english, Language.russian),
          wordToLookUp);

      expect(article.words.isEmpty, false);

      final expectedText = wordToLookUp.toLowerCase().trim();
      expect(article.words.every((w) => w.text == expectedText), true);

      expect(new Set.from(article.words.map((w) => w.partOfSpeech)).length,
          article.words.length);
    }));
  });

  testWidgets('Retrieves lemmas for a text', (tester) async {
    await tester
        .pumpWidget(RootWidgetMock.buildAsAppHome(onBuilding: (context) async {
      const wordToLookUp = ' WoRld  ';
      final lemmas = await new AssetDictionaryProvider(context).searchForLemmas(
          WordDictionaryTester.buildLangPair(
              Language.english, Language.russian),
          wordToLookUp);

      expect(lemmas.length, 6);

      final expectedText = wordToLookUp.toLowerCase().trim();
      expect(lemmas.every((l) => l.startsWith(expectedText)), true);
    }));
  });

  testWidgets('Retrieves an empty article for a non-existent word',
      (tester) async {
    await tester
        .pumpWidget(RootWidgetMock.buildAsAppHome(onBuilding: (context) async {
      final article = await new AssetDictionaryProvider(context).lookUp(
          WordDictionaryTester.buildLangPair(
              Language.english, Language.russian),
          Randomiser.nextString());
      expect(article.words.isEmpty, true);
    }));
  });
}
