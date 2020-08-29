class StoredWord {
    final int id;

    final String text;

    final String transcription;

    final String partOfSpeech;

    final String translation;

    StoredWord(this.text, { int id, String transcription, this.partOfSpeech, this.translation }):
        id = id ?? 0,
        transcription = transcription ?? '';
}
