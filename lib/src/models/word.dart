class Word {
    final String text;

    final String transcription;

    final String partOfSpeech;

    final List<String> translations;

    Word.fromJson(Map<String, dynamic> json):
        text = json['text'],
        transcription = json['ts'],
        partOfSpeech = json['pos'],
        translations = _decodeTranslations(json['tr']);

    static List<String> _decodeTranslations(List<dynamic> translationJson) =>
        translationJson.map((value) => value['text'] as String).toList();
}
