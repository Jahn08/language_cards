class Word {
    static const String _default_part_of_speech = 'collocation';

    static const List<String> parts_of_speech = [
        'adjective',
        'adverb',
        _default_part_of_speech,
        'conjunction',
        'idiom',
        'interjection',
        'noun',
        'participle',
        'preposition',
        'pronoun',
        'verb'
    ];

    final int id;

    final String text;

    final String transcription;

    final String partOfSpeech;

    final List<String> translations;

    Word(this.text, { int id, String transcription, String partOfSpeech, List<String> translations }):
        id = id,
        transcription = transcription ?? '',
        partOfSpeech = _lookUpPartOfSpeech(partOfSpeech),
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

    static String _lookUpPartOfSpeech(String givenPos) =>
        parts_of_speech.firstWhere((pos) => givenPos == pos, 
            orElse: () => _default_part_of_speech);
}
