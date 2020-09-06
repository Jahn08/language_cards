import './stored_entity.dart';

class StoredWord extends StoredEntity {
    int _deckId;
    
    final String text;

    final String transcription;

    final String partOfSpeech;

    final String translation;

    StoredWord(this.text, { int id, int deckId, String transcription, 
        this.partOfSpeech, this.translation }):
        _deckId = deckId ?? 0,
        transcription = transcription ?? '',
        super(id: id);

    int get deckId => _deckId;

    set deckId(int value) {
        _deckId = getIdFromValue(value, _deckId);
    }
}
