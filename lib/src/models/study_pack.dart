import './stored_pack.dart';

class StudyPack {

    final StoredPack pack;

    final Map<int, int> cardsByStage;

    final int cardsOverall;

    StudyPack(this.pack, Map<int, int> cardsByStage): 
        cardsByStage = cardsByStage.map((key, value) => new MapEntry(key, value)),
        cardsOverall = cardsByStage.values.fold(0, (res, v) => res + v);
}
