import './stored_entity.dart';

class StoredWord extends StoredEntity {
    int _packId;
    
    final String text;

    final String transcription;

    final String partOfSpeech;

    final String translation;

    StoredWord(this.text, { int id, int packId, String transcription, 
        this.partOfSpeech, this.translation }):
        _packId = packId ?? 0,
        transcription = transcription ?? '',
        super(id: id);

    int get packId => _packId;

    set packId(int value) {
        _packId = getIdFromValue(value, _packId);
    }
}
