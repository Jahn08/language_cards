import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:language_cards/src/data/word_dictionary.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/word.dart';
import '../utilities/http_responder.dart';
import '../utilities/randomiser.dart';

void main() {
    test('Returns a word article describing word translations and properties', () async {
        const String wordToLookUp = 'flatter';

        final client = new MockClient((request) async => HttpResponder.respondWithJson({
            "def": [
                {"text": wordToLookUp, "pos": "verb", "ts": "ˈflætə", "tr": [
                    {"text": "льстить", "pos": "verb", "asp":" несов", "syn": [
                        {"text": "тешить", "pos": "verb", "asp": "несов"},
                        {"text": "обольщать","pos": "verb","asp": "несов"},
                        {"text": "польстить","pos": "verb","asp": "сов"}], "mean":[
                            {"text": "flattery"},
                            {"text": "amuse"},
                            {"text": "deceive"},
                            {"text": "please"}
                        ]
                    },
                    {"text": "захваливать", "pos": "verb","asp": "несов"}
                ]},
                {"text": wordToLookUp, "pos": "adjective", "ts": "ˈflætə", "tr":[
                    {"text": "лестный","pos": "adjective","mean": [
                        {"text":"flattering"}
                    ]}
                ]},
                {"text": wordToLookUp, "pos": "noun","ts": "ˈflætə", "tr": [
                    {"text": "лесть", "pos": "noun", "gen": "ж","mean": [
                        {"text":"flattery"}]
                    }
                ]}
            ]
        }));

        final article = await new WordDictionary(Randomiser.nextString(), 
            from: Language.english, client: client).lookUp(wordToLookUp);
        final words = article?.words;

        const int expectedWordNumber = 3;
        expect(words?.length, expectedWordNumber);
        expect(words.map((word) => word.partOfSpeech).toSet().length, expectedWordNumber);
        expect(words.map((word) => word.transcription).toSet().length, 1);

        words.forEach((word) { 
            expect(word.text, wordToLookUp);
            expect(word.translations.isEmpty, false);
        });
    });

    test('Returns an empty word article for an unknown word', () async {
        final client = new MockClient((request) async => HttpResponder.respondWithJson(_emptyArticle));

        final unknownWord = Randomiser.nextString();
        final article = await new WordDictionary(Randomiser.nextString(), 
            from: Language.english, client: client).lookUp(unknownWord);
        expect(article?.words?.length, 0);
    });

    test('Sends request to a properly built URL with containing an api key and searched word', 
        () async {
            Uri url;
            final client = new MockClient((request) async {
                url = request.url;
                return HttpResponder.respondWithJson(_emptyArticle);
            });

            final expectedWord = Randomiser.nextString();
            final expectedApiKey = Randomiser.nextString();
            await new WordDictionary(expectedApiKey, 
                client: client, from: Language.english).lookUp(expectedWord);
            
            expect(url == null, false);
            expect(url.query?.isEmpty, false);

            expect(url.queryParameters['key'], expectedApiKey);
            expect(url.queryParameters['text'], expectedWord);
        });

        test('Gets a word article with a default part of speech when it is not recognisable', 
            () async {
            final wordToLookUp = Randomiser.nextString();
            final client = new MockClient((request) async => HttpResponder.respondWithJson({
                "def": List<dynamic>.generate(3, (index) => {
                    "text": wordToLookUp,
                    "pos": Randomiser.nextString(), 
                    "ts": Randomiser.nextString(), 
                    "tr": [{ "text": Randomiser.nextString() }]
                })
            }));

            final article = await new WordDictionary(Randomiser.nextString(), 
                from: Language.english, client: client).lookUp(wordToLookUp);
            final words = article?.words;

            final defaultPartOfSpeech = words?.first?.partOfSpeech;
            expect(defaultPartOfSpeech == null, false);
            expect(Word.parts_of_speech.contains(defaultPartOfSpeech), true);

            expect(words?.every((w) => w.partOfSpeech == defaultPartOfSpeech), true);
        });
}

Object get _emptyArticle => ({
    "def": []
});
