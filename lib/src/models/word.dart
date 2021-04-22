import 'part_of_speech.dart';

class Word {

    final int id;

    final String text;

    final String transcription;

    final PartOfSpeech partOfSpeech;

    final List<String> translations;

    Word(this.text, 
		{ int id, String transcription, PartOfSpeech partOfSpeech, List<String> translations }):
        id = id,
        transcription = transcription ?? '',
        partOfSpeech = partOfSpeech,
        translations = translations ?? [];

    Word.fromJson(Map<String, dynamic> json):
        id = null,
        text = json['text'],
        transcription = json['ts'],
        partOfSpeech = _lookUpPartOfSpeech(json['pos']),
        translations = _decodeTranslations(json['tr']);

    String get translationString => translations.join('; ');

    static List<String> _decodeTranslations(List<dynamic> translationJson) =>
        translationJson.map((value) => value['text'] as String).toList();

    static PartOfSpeech _lookUpPartOfSpeech(String givenPos) =>
        PartOfSpeech.retrieve(givenPos) ?? PartOfSpeech.collocation;

	@override
	bool operator ==(Object obj) => obj?.runtimeType == runtimeType && obj.hashCode == hashCode;

	@override
	int get hashCode => text.hashCode + partOfSpeech.hashCode;
}
