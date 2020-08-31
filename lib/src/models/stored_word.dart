class StoredWord {
    int _id;

    final String text;

    final String transcription;

    final String partOfSpeech;

    final String translation;

    StoredWord(this.text, { int id, String transcription, this.partOfSpeech, this.translation }):
        _id = id ?? 0,
        transcription = transcription ?? '';

    int get id => _id;

    set id(int value) {
        if (_id == 0 && value > 0)
            _id = value;
    }
}
