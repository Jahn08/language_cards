import '../models/study_pack.dart';

export '../models/study_pack.dart';

abstract class StudyStorage {

    Future<List<StudyPack>> fetchStudyPacks();
}
