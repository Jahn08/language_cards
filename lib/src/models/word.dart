import 'part_of_speech.dart';

class Word {

    final String text;

	final int id;

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
		this(
			json['text'],
			transcription: json['ts'], 
			partOfSpeech: _lookUpPartOfSpeech(json['pos']),
			translations: _decodeTranslations(json['tr'])
		);

	static PartOfSpeech _lookUpPartOfSpeech(String givenPos) =>
        PartOfSpeech.retrieve(givenPos) ?? PartOfSpeech.collocation;

    String get translationString => translations.join('; ');

    static List<String> _decodeTranslations(List<dynamic> translationJson) =>
        translationJson.map((value) => value['text'] as String).toList();

	@override
	bool operator ==(Object obj) => obj?.runtimeType == runtimeType && obj.hashCode == hashCode;

	@override
	int get hashCode => [text.hashCode, partOfSpeech.hashCode].join().hashCode;
}

class AssetWord extends Word {

    AssetWord(String text, 
		{ int id, String transcription, PartOfSpeech partOfSpeech, List<String> translations }):
		super(text, id: id, transcription: transcription, 
			partOfSpeech: partOfSpeech, translations: translations);

    AssetWord.fromJson(String text, Map<String, dynamic> json):
		super(
			text,
			transcription: json['s'], 
			partOfSpeech: Word._lookUpPartOfSpeech(json['p']),
			translations: (json['r'] as List).cast<String>()
		);
}
