import 'part_of_speech.dart';

class Word {
  final String text;

  final int? id;

  final String transcription;

  final PartOfSpeech? partOfSpeech;

  final List<String> translations;

  const Word(this.text,
      {this.id,
      this.partOfSpeech,
      String? transcription,
      List<String>? translations})
      : transcription = transcription ?? '',
        translations = translations ?? const [];

  Word.fromJson(Map<String, dynamic> json)
      : this(json['text'] as String,
            transcription: json['ts'] as String,
            partOfSpeech: _lookUpPartOfSpeech(json['pos'] as String),
            translations: _decodeTranslations(json['tr'] as List<dynamic>));

  static PartOfSpeech _lookUpPartOfSpeech(String? givenPos) =>
      PartOfSpeech.retrieve(givenPos);

  String get translationString => translations.join('; ');

  static List<String> _decodeTranslations(List<dynamic> translationJson) =>
      // ignore: avoid_dynamic_calls
      translationJson.map((value) => value['text'] as String).toList();

  @override
  bool operator ==(Object obj) =>
      obj.runtimeType == runtimeType && obj.hashCode == hashCode;

  @override
  int get hashCode => [text.hashCode, partOfSpeech.hashCode].join().hashCode;
}

class AssetWord extends Word {
  AssetWord(super.text,
      {super.id, super.transcription, super.partOfSpeech, super.translations});

  AssetWord.fromJson(String text, Map<String, dynamic> json)
      : super(json['t'] as String? ?? text,
            transcription: json['s'] as String?,
            partOfSpeech: Word._lookUpPartOfSpeech(json['p'] as String?),
            translations:
                json['r'] == null ? null : (json['r'] as List).cast<String>());
}
