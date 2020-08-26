class Word {
    static const String _DEFAULT_PART_OF_SPEECH = 'collocation';

    static const List<String> PARTS_OF_SPEECH = [
        'adjective',
        'adverb',
        _DEFAULT_PART_OF_SPEECH,
        'conjunction',
        'idiom',
        'interjection',
        'noun',
        'participle',
        'preposition',
        'pronoun',
        'verb'
    ];

    final String text;

    final String transcription;

    final String partOfSpeech;

    final List<String> translations;

    Word(String text, { String transcription, String partOfSpeech, List<String> translations }):
        text = text,
        transcription = transcription ?? '',
        partOfSpeech = _lookUpPartOfSpeech(partOfSpeech),
        translations = translations ?? [];

    Word.fromJson(Map<String, dynamic> json):
        text = json['text'],
        transcription = json['ts'],
        partOfSpeech = _lookUpPartOfSpeech(json['pos']),
        translations = _decodeTranslations(json['tr']);

    static List<String> _decodeTranslations(List<dynamic> translationJson) =>
        translationJson.map((value) => value['text'] as String).toList();

    static String _lookUpPartOfSpeech(String givenPos) =>
        PARTS_OF_SPEECH.firstWhere((pos) => givenPos == pos, 
            orElse: () => _DEFAULT_PART_OF_SPEECH);
}
