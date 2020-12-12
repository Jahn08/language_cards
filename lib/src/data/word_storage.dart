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
            orderBy: StoredWord.textFieldName, parentIds: parentIds,
            parentField: StoredWord.packIdFieldName);

    @override
    List<StoredWord> convertToEntity(List<Map<String, dynamic>> values) => 
        values.map((w) => new StoredWord.fromDbMap(w)).toList();

    Future<Map<int, int>> groupByParent(List<int> parentIds) async {
        final groups = (await connection.groupBy<int>(entityName, 
            groupField: StoredWord.packIdFieldName, groupValues: parentIds));
        return new Map<int, int>.fromIterable(groups, 
            key: (g) => g[StoredWord.packIdFieldName], value: (g) => g.length);
    }

    Future<Map<int, Map<int, int>>> groupByStudyLevels() async {
        final groups = await connection.groupBySeveral(entityName, 
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
