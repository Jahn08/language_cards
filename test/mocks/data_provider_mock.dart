import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/data_group.dart';
import 'package:language_cards/src/data/data_provider.dart';
import 'package:language_cards/src/models/stored_entity.dart';

abstract class DataProviderMock<T extends StoredEntity> extends DataProvider {

	final List<T> items;

	List<String> _intFields;

	DataProviderMock(this.items): assert(items != null);

	@override
	Future<int> count(String tableName, { Map<String, dynamic> filters }) =>
		Future.value(_getFilteredItemProps(filters).length);

	@override
	Future<List<int>> add(String tableName, List<Map<String, dynamic>> entities) {
		int newId = (items..sort((a, b) => a.id.compareTo(b.id))).last.id;
		final newItems = entities.map((e) {
			final i = buildFromDbMap(e);
			i.id = ++newId;
			return i;
		}).toList();
		items.addAll(newItems);

		return Future.value(newItems.map((p) => p.id).toList());
	}

	T buildFromDbMap(Map<String, dynamic> map); 

	@override
	Future<void> close() => Future.value();

	@override
	Future<int> delete(String tableName, List<int> ids) => _remove(ids);

	Future<int> _remove(List<int> ids) {
		final prevLength = items.length;
		final newLength = (items..removeWhere((p) => ids.contains(p.id))).length;

		return Future.value(prevLength - newLength);
	}

	@override
	Future<List<Map<String, dynamic>>> fetch(String tableName, {
		@required String orderBy, int take, int skip, Map<String, dynamic> filters
	}) {
		var propItems = _getFilteredItemProps(filters);

		if (orderBy != null && orderBy.isNotEmpty)
			// ignore: avoid_dynamic_calls
			propItems = propItems.toList()..sort((a, b) => a[orderBy].compareTo(b[orderBy]) as int);

		if (skip != null)
			propItems = propItems.skip(skip);

		if (take != null)
			propItems = propItems.take(take);

		return Future.value(propItems.toList());
	}

	Iterable<Map<String, dynamic>> _getFilteredItemProps(Map<String, dynamic> filters) {
		var propItems = items.map((i) => i.toDbMap());
		if (filters != null && filters.isNotEmpty) {
			const String anySymbolPattern = '%';
			propItems = propItems.where((i) => 
				filters.entries.every((f) {
					if (f.value is List<dynamic>) 
						return (f.value as List<dynamic>).contains(i[f.key]);
					else if (f.value is String && (f.value as String).endsWith(anySymbolPattern))
						return (i[f.key] as String).startsWith(
							(f.value as String).split(anySymbolPattern).first);

					return i[f.key] == f.value;
				}));
		}
	
		return propItems;
	}

	@override
	Future<Map<String, dynamic>> findById(String tableName, dynamic id) {
		final item = items.singleWhere((p) => p.id == id, orElse: () => null);
		return Future.value(item?.toDbMap());
	}

	@override
	Future<List<DataGroup>> groupBy(String tableName, { 
		@required String groupField, List<dynamic> groupValues, Map<String, dynamic> filters
	}) => _groupBySeveral(tableName, groupFields: [groupField], groupValues: { groupField: groupValues },
		filters: filters);

	Future<List<DataGroup>> _groupBySeveral(String tableName, { 
		@required List<String> groupFields, 
		Map<String, List<dynamic>> groupValues,
		Map<String, dynamic> filters
	}) {
		groupValues ??= {};
			
		final intFields = _getIntFields();
		final groupFieldsOverall = groupFields.length;
		const valSeparator = '|';
		return Future.value(_getFilteredItemProps(filters).fold<Map<String, int>>({}, 
			(map, i) {
				final vals = groupFields
					.where((f) => !groupValues.containsKey(f) || groupValues[f].contains(i[f]))
					.map((f) => i.containsKey(f) ? i[f]: i[indexFieldName].toString()[0]).toList();
				
				if (vals.length != groupFieldsOverall)
					return map;

				final key = vals.map((v) => v?.toString()).join(valSeparator);
				if (map[key] == null)
					map[key] = 0;

					map[key] += 1;				
				return map;
			}).entries.map((e) {
				final obj = <String, dynamic>{ DataGroup.lengthField: e.value };
				
				int index = 0;
				e.key.split(valSeparator).forEach((v) {
					final grField = groupFields[index++];
					obj[grField] = intFields.contains(grField) ? int.tryParse(v): v;
				});
				return new DataGroup(obj);
			}).toList());
	}

	@override
	Future<List<DataGroup>> groupBySeveral(String tableName, { 
		@required List<String> groupFields, Map<String, List<dynamic>> groupValues
	}) => _groupBySeveral(tableName, groupFields: groupFields, groupValues: groupValues);

	List<String> _getIntFields() => _intFields ??= intFieldNames;

	@protected
	List<String> get intFieldNames => [StoredEntity.idFieldName];

	@protected
	String get indexFieldName;

	@override
	Future<void> update(String tableName, List<Map<String, dynamic>> entities) async {
		final updatedItems = entities.map((e) => buildFromDbMap(e)).toList();

		final idsToDelete = updatedItems.map((p) => p.id).toList();
		await _remove(idsToDelete);
		
		items.addAll(updatedItems);
	}
}
