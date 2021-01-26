import 'package:meta/meta.dart';
import './db_provider.dart';
import '../models/stored_entity.dart';
import '../models/stored_pack.dart';
import '../models/stored_word.dart';

abstract class BaseStorage<T extends StoredEntity> {
    static const int itemsPerPageByDefault = 10;
    
    static final _entities = <StoredEntity>[new StoredWord(''), new StoredPack('')];

    @protected
    String get entityName;

    @protected
    DbProvider get connection => DbProvider.getInstance(_entities);

    Future<List<T>> fetch({ String textFilter, int skipCount, int takeCount }) => 
        fetchInternally(textFilter: textFilter, takeCount: takeCount, skipCount: skipCount);

    @protected
    Future<List<T>> fetchInternally({ int skipCount, int takeCount, 
        String orderBy, String textFilter, Map<String, List<dynamic>> filters }) async {
			final inFilters = new Map<String, dynamic>.from(filters ?? {});

			if (textFilter != null && textFilter.isNotEmpty)
				inFilters[textFilterFieldName] = '$textFilter%';

            final wordValues = await connection.fetch(entityName, 
                take: takeCount, 
                filters: inFilters,
                orderBy: orderBy, 
                skip: skipCount);
            return convertToEntity(wordValues);
        }

	@protected
	String get textFilterFieldName;

    Future<void> closeConnection() => DbProvider.close();

    Future<T> upsert(T entity) async {
        if (entity.isNew)
            entity.id = await connection.add(entityName, entity.toDbMap());
        else
            await update([entity]);
        
        return entity;         
    }

    Future<void> update(List<T> entities) async {
        await connection.update(entityName, 
            entities.map((w) => w.toDbMap()).toList());
    }

    Future<T> find(int id) async {
        final values = await connection.findById(entityName, id); 
        return values == null ? null: convertToEntity([values]).first;
    }

    Future<void> delete(List<int> ids) async {
        await connection.delete(entityName, ids);
    }

    @protected
    List<T> convertToEntity(List<Map<String, dynamic>> values);

	Future<List<String>> groupByTextIndex([Map<String, List<dynamic>> groupValues]) async {
		final mainGroupFieldKey = connection.composeSubstrFunc(textFilterFieldName, 1);
		final groupFields = [mainGroupFieldKey];

		if (groupValues != null && groupValues.isNotEmpty)
			groupFields.addAll(groupValues.keys);

		final groups = (await connection.groupBySeveral(entityName, 
            groupFields: groupFields, groupValues: groupValues));
        return groups.map((g) => g.fields[mainGroupFieldKey] as String)
			.toList()..sort();
	}
}
