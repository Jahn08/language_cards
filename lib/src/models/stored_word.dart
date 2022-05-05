import 'part_of_speech.dart';
import 'stored_entity.dart';
import 'stored_pack.dart';
import 'word_study_stage.dart';

class StoredWord extends StoredEntity {
    static const String entityName = 'Cards';

    static const textFieldName = 'text';
    static const transcriptionFieldName = 'transcription';
    static const partOfSpeechFieldName = 'part_of_speech';
    static const translationFieldName = 'translation';
    static const studyProgressFieldName = 'study_progress';
    static const packIdFieldName = 'pack_id';

    int _packId;
    
    final String text;

    final String transcription;

    final PartOfSpeech partOfSpeech;

    final String translation;

    int _studyProgress;

    StoredWord(this.text, { int id, int packId, String transcription, 
        int studyProgress, this.translation, this.partOfSpeech }):
        _packId = packId,
        transcription = transcription ?? '',
        _studyProgress = studyProgress ?? WordStudyStage.unknown,
        super(id: id);

    StoredWord.fromDbMap(Map<String, dynamic> values):
        this(values[textFieldName] as String, 
            id: values[StoredEntity.idFieldName] as int, 
            packId: values[packIdFieldName] as int,
            transcription: values[transcriptionFieldName] as String,
            studyProgress: values[studyProgressFieldName] as int,
            partOfSpeech: PartOfSpeech.retrieve(values[partOfSpeechFieldName] as String),
            translation: values[translationFieldName] as String);

    int get packId => _packId;

    set packId(int value) {
        _packId = getIdFromValue(value, _packId);
    }

    int get studyProgress => _studyProgress;
    
    bool incrementProgress() {
        final newStage = WordStudyStage.nextStage(_studyProgress);

        if (newStage == _studyProgress)
            return false;

        _studyProgress = newStage;
        return true;
    }

    void resetStudyProgress() => _studyProgress = WordStudyStage.unknown;

    @override
    String get tableName => entityName;

    @override
    String get foreignTableName => StoredPack.entityName;

    @override
    Map<String, dynamic> toDbMap({ bool excludeIds }) {
        final map = super.toDbMap(excludeIds: excludeIds);
        map.addAll({
            textFieldName: text,
            transcriptionFieldName: transcription,
            partOfSpeechFieldName: partOfSpeech?.toString(),
            translationFieldName: translation,
            studyProgressFieldName: studyProgress,
            if (!(excludeIds ?? false))
				packIdFieldName: packId
        });

        return map;
    }

    @override
    String get columnsExpr => 
        """ $textFieldName TEXT NOT NULL,
            $transcriptionFieldName TEXT,
            $partOfSpeechFieldName TEXT,
            $translationFieldName TEXT NOT NULL,
            $studyProgressFieldName INTEGER NOT NULL,
            $packIdFieldName INTEGER,
            FOREIGN KEY($packIdFieldName) 
                REFERENCES $foreignTableName(${StoredEntity.idFieldName}) ON DELETE SET NULL """;

	@override
	String get textData => text;
}
