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

    Future<List<T>> fetch({ int skipCount, int takeCount, List<int> parentIds });

    @protected
    Future<List<T>> fetchInternally({ int takeCount, int skipCount, 
        String orderBy, List<int> parentIds, String parentField }) async {
            final wordValues = await connection.fetch(entityName, 
                take: takeCount ?? itemsPerPageByDefault, 
                filters: parentIds == null || parentIds.length == 0 ? null: 
                    { parentField: parentIds },
                orderBy: orderBy, 
                skip: skipCount);
            return convertToEntity(wordValues);
        }

    Future<void> closeConnection() async {
        await DbProvider.close();
    }

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
}
