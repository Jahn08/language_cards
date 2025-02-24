import 'package:meta/meta.dart';
import 'db_provider.dart';
import 'data_provider.dart';
import '../models/stored_entity.dart';
import '../models/stored_pack.dart';
import '../models/stored_word.dart';

abstract class BaseStorage<T extends StoredEntity> {
  static final _entities = <StoredEntity>[
    new StoredWord(''),
    new StoredPack('')
  ];

  static DataProvider? _provider;

  const BaseStorage();

  @protected
  String get entityName;

  @protected
  DataProvider get connection =>
      _provider ?? (_provider = new DbProvider(_entities));

  Future<List<T>> fetch({String? textFilter, int? skipCount, int? takeCount});

  Future<int> count({String? textFilter}) {
    return connection.count(entityName,
        filters: addTextFilterClause(textFilter: textFilter));
  }

  @protected
  Future<List<T>> fetchInternally(
      {required String orderBy,
      List<String>? columns,
      int? skipCount,
      int? takeCount,
      String? textFilter,
      Map<String, List<dynamic>>? filters}) async {
    final inFilters =
        addTextFilterClause(filters: filters, textFilter: textFilter);
    final wordValues = await connection.fetch(entityName,
        take: takeCount,
        filters: inFilters,
        orderBy: orderBy,
        skip: skipCount,
        columns: columns);
    return convertToEntity(wordValues);
  }

  @protected
  Map<String, dynamic> addTextFilterClause(
      {Map<String, dynamic>? filters, String? textFilter}) {
    final inFilters = new Map<String, dynamic>.from(filters ?? {});
    if (textFilter != null && textFilter.isNotEmpty)
      inFilters[textFilterFieldName] = '$textFilter%';

    return inFilters;
  }

  @protected
  String get textFilterFieldName;

  Future<void>? closeConnection() => _provider?.close();

  Future<List<T>> upsert(List<T> entities) async {
    final toInsert = entities.where((e) => e.isNew).toList();
    final toUpdate = entities.where((e) => !e.isNew).toList();

    return new List<T>.from(await _insert(toInsert))
      ..addAll(await _update(toUpdate));
  }

  Future<List<T>> _insert(List<T> entities) async {
    if (entities.isEmpty) return entities;

    final ids = await connection.add(
        entityName, entities.map((w) => w.toDbMap()).toList());
    int index = 0;
    for (final id in ids) entities[index++].id = id;

    return entities;
  }

  Future<List<T>> _update(List<T> entities) async {
    if (entities.isEmpty) return entities;

    await connection.update(
        entityName, entities.map((w) => w.toDbMap()).toList());
    return entities;
  }

  Future<T?> find(int? id) async {
    if (id == null) return null;

    final values = await connection.findById(entityName, id);
    return values == null ? null : convertToEntity([values]).first;
  }

  Future<void> delete(List<int?> ids) async {
    await connection.delete(entityName, ids);
  }

  @protected
  List<T> convertToEntity(List<Map<String, dynamic>> values);

  @protected
  Future<Map<String, int>> groupByTextIndex(
      [Map<String, List<dynamic>>? groupValues]) async {
    final mainGroupFieldKey =
        DbProvider.composeSubstrFunc(textFilterFieldName, 1);
    final groupFields = [mainGroupFieldKey];

    if (groupValues != null && groupValues.isNotEmpty)
      groupFields.addAll(groupValues.keys);

    final groups = await connection.groupBySeveral(entityName,
        groupFields: groupFields, groupValues: groupValues);

    final entries = <String, int>{};
    groups.forEach((g) {
      final key = g.fields[mainGroupFieldKey] as String;
      entries[key] = (entries[key] ?? 0) + g.length;
    });
    return entries;
  }
}
