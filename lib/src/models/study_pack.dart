import './stored_pack.dart';
import './word_study_stage.dart';

class StudyPack {

    final StoredPack pack;

    final Map<String, int> cardsByStage;

    final int cardsOverall;

    StudyPack(this.pack, Map<int, int> cardsByStage): 
        cardsByStage = cardsByStage.map((key, value) => 
            new MapEntry(WordStudyStage.stringify(key), value)),
        cardsOverall = cardsByStage.values.fold(0, (res, v) => res + v);
}
