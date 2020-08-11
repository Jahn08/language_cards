import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:language_cards/src/data/word_dictionary.dart';
import '../utilities/randomiser.dart';

void main() {
    test('Returns a word article describing word translations and properties', () async {
        const String wordToLookUp = 'flatter';

        final client = new MockClient((request) async =>_buildJsonResponse({
            "head": {},
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

        final article = await new WordDictionary(Randomiser.buildRandomString(), client: client)
            .lookUp(wordToLookUp);
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
        final client = new MockClient((request) async => _buildJsonResponse(_emptyArticle));

        final unknownWord = Randomiser.buildRandomString();
        final article = await new WordDictionary(Randomiser.buildRandomString(), client: client)
            .lookUp(unknownWord);
        expect(article?.words?.length, 0);
    });

    test('Sends request to a properly built URL with containing an api key and searched word', 
        () async {
            Uri url;
            final client = new MockClient((request) async {
                url = request.url;
                return _buildJsonResponse(_emptyArticle);
            });

            final expectedWord = Randomiser.buildRandomString();
            final expectedApiKey = Randomiser.buildRandomString();
            await new WordDictionary(expectedApiKey, client: client).lookUp(expectedWord);
            
            expect(url == null, false);
            expect(url.query?.isEmpty, false);

            expect(url.queryParameters['key'], expectedApiKey);
            expect(url.queryParameters['text'], expectedWord);
        });
}

Response _buildJsonResponse(Object body) {
    return new Response(
        json.encode(body),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'}
    );
}

Object get _emptyArticle => ({
    "head": {},
    "def": []
});
