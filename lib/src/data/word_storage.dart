import 'package:flutter/cupertino.dart';
import '../data/base_storage.dart';
import '../models/stored_word.dart';

export '../models/stored_word.dart';
export '../data/base_storage.dart';

class WordStorage extends BaseStorage<StoredWord> {

    @override
    String get entityName => StoredWord.entityName;

    Future<List<StoredWord>> fetchFiltered({ List<int> parentIds, List<int> studyStageIds,
        String text, int skipCount, int takeCount }) =>
        _fetchInternally(skipCount: skipCount, takeCount: takeCount, 
            parentIds: parentIds, studyStageIds: studyStageIds, text: text);

    Future<List<StoredWord>> _fetchInternally({ List<int> parentIds, List<int> studyStageIds,
		String text, int skipCount, int takeCount }) {
            final filters = new Map<String, List<dynamic>>();

            if (parentIds != null && parentIds.length > 0)
                filters[_parentIdField] = parentIds;

            if (studyStageIds != null && studyStageIds.length > 0)
                filters[StoredWord.studyProgressFieldName] = studyStageIds;

            return super.fetchInternally(skipCount: skipCount, takeCount: takeCount, 
                orderBy: StoredWord.textFieldName, filters: filters, textFilter: text);
        }
	
	String get _parentIdField => StoredWord.packIdFieldName;

	@override
	String get textFilterFieldName => StoredWord.textFieldName;

    @override
    List<StoredWord> convertToEntity(List<Map<String, dynamic>> values) => 
        values.map((w) => new StoredWord.fromDbMap(w)).toList();

    Future<Map<int, int>> groupByParent(List<int> parentIds) async {
        final groups = (await connection.groupBy(entityName, 
            groupField: StoredWord.packIdFieldName, groupValues: parentIds));
        return new Map<int, int>.fromIterable(groups, 
            key: (g) => g[StoredWord.packIdFieldName], value: (g) => g.length);
    }

    Future<Map<int, Map<int, int>>> groupByStudyLevels() async {
        final groups = await connection.groupBySeveral(entityName, 
            groupFields: [_parentIdField, StoredWord.studyProgressFieldName]);

        return groups.fold<Map<int, Map<int, int>>>(new Map<int, Map<int, int>>(),
            (res, gr) {
                final packId = gr[_parentIdField] as int;
                if (!res.containsKey(packId))
                    res[packId] = new Map<int, int>();

                res[packId][gr[StoredWord.studyProgressFieldName] as int] = gr.length;
                return res;
            });
    }

	Future<Map<String, int>> groupByTextIndexAndParent([List<int> parentIds]) => 
		groupByTextIndex(parentIds == null || parentIds.isEmpty ? 
			null: { _parentIdField: parentIds });

	@protected
	@override
	Future<Map<String, int>> groupByTextIndex([Map<String, List<dynamic>> groupValues]) =>
		super.groupByTextIndex();
}
