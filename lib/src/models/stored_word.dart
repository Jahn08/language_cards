import './stored_entity.dart';
import './word_study_stage.dart';

class StoredWord extends StoredEntity {
    int _packId;
    
    final String text;

    final String transcription;

    final String partOfSpeech;

    final String translation;

    int _studyProgress;

    StoredWord(this.text, { int id, int packId, String transcription, 
        int studyProgress, this.partOfSpeech, this.translation }):
        _packId = packId ?? 0,
        transcription = transcription ?? '',
        _studyProgress = studyProgress ?? WordStudyStage.unknown,
        super(id: id);

    int get packId => _packId;

    set packId(int value) {
        _packId = getIdFromValue(value, _packId);
    }

    int get studyProgress => _studyProgress;

    void resetStudyProgress() => _studyProgress = WordStudyStage.unknown;
}
