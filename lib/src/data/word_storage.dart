import '../data/base_storage.dart';
import '../models/stored_word.dart';

export '../models/stored_word.dart';
export '../data/base_storage.dart';

class WordStorage extends BaseStorage<StoredWord> {

    @override
    String get entityName => StoredWord.entityName;

    Future<List<StoredWord>> fetch({ List<int> parentIds, int skipCount, int takeCount }) async {
        return fetchInternally(skipCount: skipCount, takeCount: takeCount, 
            orderBy: StoredWord.textFieldName, parentField: StoredWord.packIdFieldName,
            parentIds: parentIds);
    }

    @override
    List<StoredWord> convertToEntity(List<Map<String, dynamic>> values) => 
        values.map((w) => new StoredWord.fromDbMap(w)).toList();

    Future<Map<int, int>> getLength(List<int> parentIds) {
        return connection.getGroupLength<int>(entityName, 
            groupField: StoredWord.packIdFieldName, groupValues: parentIds);
    }
}
