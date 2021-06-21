import 'package:meta/meta.dart';
import 'db_provider.dart';
import 'data_provider.dart';
import '../models/stored_entity.dart';
import '../models/stored_pack.dart';
import '../models/stored_word.dart';

abstract class BaseStorage<T extends StoredEntity> {
    
    static final _entities = <StoredEntity>[new StoredWord(''), new StoredPack('')];

	static DataProvider _provider;

    @protected
    String get entityName;

    @protected
    DataProvider get connection => _provider ?? (_provider = new DbProvider(_entities));

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

    Future<void> closeConnection() => _provider?.close();

    Future<List<T>> upsert(List<T> entities) async =>
		new List<T>.from(await _insert(entities.where((e) => e.isNew).toList()))
			..addAll(await _update(entities.where((e) => !e.isNew).toList()));
	
    Future<List<T>> _insert(List<T> entities) async {
		if (entities.isEmpty)
			return entities;

        final ids = await connection.add(entityName, 
            entities.map((w) => w.toDbMap()).toList());
		int index = 0;
		for (final id in ids)
			entities[index++].id = id;

		return entities;
	}

    Future<List<T>> _update(List<T> entities) async {
		if (entities.isEmpty)
			return entities;

        await connection.update(entityName, 
            entities.map((w) => w.toDbMap()).toList());
		return entities;
    }

    Future<T> find(int id) async {
		if (id == null)
			return null;

        final values = await connection.findById(entityName, id); 
        return values == null ? null: convertToEntity([values]).first;
    }

    Future<void> delete(List<int> ids) async {
        await connection.delete(entityName, ids);
    }

    @protected
    List<T> convertToEntity(List<Map<String, dynamic>> values);

	Future<Map<String, int>> groupByTextIndex([Map<String, List<dynamic>> groupValues]) async {
		final mainGroupFieldKey = DbProvider.composeSubstrFunc(textFilterFieldName, 1);
		final groupFields = [mainGroupFieldKey];

		if (groupValues != null && groupValues.isNotEmpty)
			groupFields.addAll(groupValues.keys);

		final groups = (await connection.groupBySeveral(entityName, 
            groupFields: groupFields, groupValues: groupValues));
        return new Map.fromEntries(
			groups.map((g) => new MapEntry(g.fields[mainGroupFieldKey] as String, g.length)));
	}
}
