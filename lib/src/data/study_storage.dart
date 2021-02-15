import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/study_pack.dart';

export '../models/study_pack.dart';

abstract class StudyStorage {

    Future<List<StudyPack>> fetchStudyPacks(AppLocalizations locale);
}
