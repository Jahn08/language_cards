import '../models/language.dart';
import '../models/study_pack.dart';

export '../models/study_pack.dart';

mixin StudyStorage {
  Future<List<StudyPack>> fetchStudyPacks(LanguagePair? languagePair);
}
