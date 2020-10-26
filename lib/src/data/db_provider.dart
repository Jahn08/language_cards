import 'package:meta/meta.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/stored_entity.dart';

class DbProvider {
    static DbProvider _provider;

    final List<StoredEntity> _tableEntities;

    Database _db;

    DbProvider._(List<StoredEntity> tableEntities): 
        _tableEntities = tableEntities;

    static DbProvider getInstance(List<StoredEntity> tableEntities) {
        if (_provider == null)
            _provider = new DbProvider._(tableEntities);

        return _provider;
    }

    static Future<void> close() async {
        await _provider?._close();
    }

    Future<T> _perform<T>(String tableName, Future<T> Function() action) async {
        try {
            if (!_tableEntities.any((e) => e.tableName == tableName))
                throw new Exception('The table "$tableName" is not in the list of entities');

            await _init();
            return action();
        }
        catch (ex, stack) {
            _printError('running a database script', ex, stack);
            rethrow;
        }
    }

    void _printError(String actionName, dynamic ex, StackTrace stack) => 
        print('An error while $actionName: ${ex.toString()}\nStack: ${stack.toString()}');

    Future<void> _init() async {
        if (_db != null)
            return;

        final docDir = await getApplicationDocumentsDirectory();
        final dbPath = join(docDir.path, 'language_cards.db');

        _db = await openDatabase(dbPath, 
            version: 1,
            onCreate: (newDb, _) async {
                try {
                    final creationClauses = _compileCreationClauses(_tableEntities);
                    final creationClausesLength = creationClauses.length;
                    for (int i = 0; i < creationClausesLength; ++i)
                        await newDb.execute(creationClauses[i]);
                }
                catch (ex, stack) {
                    _printError('creating a database', ex, stack);
                    rethrow;
                }
            });
    }

    List<String> _compileCreationClauses(List<StoredEntity> entities, 
        [List<String> tableNames]) {
            tableNames = tableNames ?? <String>[];

            final dependantEntitiesToCreate = <StoredEntity>[]; 
            final creationCmds = <String>[];
            
            entities.forEach((ent) { 
                if (tableNames.contains(ent.tableName))
                    return;

                if (ent.foreignTableName == null || 
                    tableNames.contains(ent.foreignTableName)) {
                    creationCmds.add(ent.tableExpr);
                    tableNames.add(ent.tableName);
                }

                dependantEntitiesToCreate.add(ent);
            });

            if (dependantEntitiesToCreate.length > 0)
                creationCmds.addAll(
                    _compileCreationClauses(dependantEntitiesToCreate, tableNames));

            return creationCmds;
        }

    Future<void> update(String tableName, List<Map<String, dynamic>> entities) async {
        await _perform<void>(tableName, () async {
                final batch = _db.batch();
                entities.forEach((values) { 
                    batch.update(tableName, 
                        values, 
                        where: '${StoredEntity.idFieldName}=?',
                        whereArgs: [values[StoredEntity.idFieldName]]);
                });

                await batch.commit(noResult: true, continueOnError: false);
            });
        }

    Future<int> add(String tableName, Map<String, dynamic> values) {
        return _perform<int>(tableName, () async => 
            _db.insert(tableName, values, conflictAlgorithm: ConflictAlgorithm.fail));
    }

    Future<int> delete(String tableName, List<dynamic> ids) {
        return _perform<int>(tableName, 
            () => _db.delete(tableName, 
                where: _composeInFilterClause(StoredEntity.idFieldName, ids),
                whereArgs: ids
            ));
    }

    String _composeInFilterClause(String fieldName, List<dynamic> values) {
        final whereParamExpr = List.filled(values.length, '?').join(', ');
        return '$fieldName IN ($whereParamExpr)';
    }
        
    Future<Map<T, int>> getGroupLength<T>(String tableName, 
        { @required String groupField, @required List<T> groupValues }) {
            final filterClause = _composeInFilterClause(groupField, groupValues);
            return _perform(tableName, () async {
                const lengthField = 'length';
                final res = await _db.rawQuery('''SELECT $groupField, COUNT(*) $lengthField 
                    FROM $tableName WHERE $filterClause GROUP BY $groupField''', 
                    groupValues);

                return new Map.fromIterable(res, key: (gr) => gr[groupField], 
                    value: (gr) => gr[lengthField] as int);
            });
        }

    Future<List<Map<String, dynamic>>> fetch(String tableName, { @required String orderBy,
        int take, int skip, Map<String, dynamic> filters }) {
            return _perform(tableName, () async => await _db.query(tableName, 
                columns: null,
                limit: take,
                offset: skip,
                orderBy: orderBy,
                where: filters == null ? null: 
                    filters.keys.map((field) => '"$field"=?').join(' AND '),
                whereArgs: filters == null ? null: filters.values.toList()
            ));
        }

    Future<Map<String, dynamic>> findById(String tableName, dynamic id) async {
        return (await _perform(tableName, () async => await _db.query(tableName, 
            columns: null,
            limit: 1,
            where: '"${StoredEntity.idFieldName}"=?',
            whereArgs: [id]
        ))).firstWhere((el) => true, orElse: null);
    }

    Future<void> _close() async {
        await _db?.close();

        _db = null;
    }
}
