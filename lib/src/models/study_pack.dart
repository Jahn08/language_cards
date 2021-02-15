import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import './stored_pack.dart';
import './word_study_stage.dart';

class StudyPack {

    final StoredPack pack;

    final Map<String, int> cardsByStage;

    final int cardsOverall;

    StudyPack(this.pack, Map<int, int> cardsByStage, AppLocalizations locale): 
        cardsByStage = cardsByStage.map((key, value) => 
            new MapEntry(WordStudyStage.stringify(key, locale), value)),
        cardsOverall = cardsByStage.values.fold(0, (res, v) => res + v);
}
