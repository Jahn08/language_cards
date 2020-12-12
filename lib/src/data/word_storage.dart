import '../data/base_storage.dart';
import '../models/stored_word.dart';

export '../models/stored_word.dart';
export '../data/base_storage.dart';

class WordStorage extends BaseStorage<StoredWord> {

    @override
    String get entityName => StoredWord.entityName;

    Future<List<StoredWord>> fetch({ List<int> parentIds, int skipCount, int takeCount }) =>
        _fetchInternally(skipCount: skipCount, takeCount: takeCount, 
            parentIds: parentIds);

    Future<List<StoredWord>> _fetchInternally({ List<int> parentIds, int skipCount, 
        int takeCount }) =>
        super.fetchInternally(skipCount: skipCount, takeCount: takeCount, 
            orderBy: StoredWord.textFieldName, parentField: StoredWord.packIdFieldName);

    @override
    List<StoredWord> convertToEntity(List<Map<String, dynamic>> values) => 
        values.map((w) => new StoredWord.fromDbMap(w)).toList();

    Future<Map<int, int>> getLength(List<int> parentIds) =>
        connection.getGroupLength<int>(entityName, 
            groupField: StoredWord.packIdFieldName, groupValues: parentIds);

    Future<Map<int, Map<int, int>>> groupByStudyLevels() async {
        final groups = await connection.countGroups(entityName, 
            groupFields: [StoredWord.packIdFieldName, StoredWord.studyProgressFieldName]);

        return groups.fold<Map<int, Map<int, int>>>(new Map<int, Map<int, int>>(),
            (res, gr) {
                final packId = gr[StoredWord.packIdFieldName] as int;
                if (!res.containsKey(packId))
                    res[packId] = new Map<int, int>();

                res[packId][gr[StoredWord.studyProgressFieldName] as int] = gr.length;
                return res;
            });
    }
}
