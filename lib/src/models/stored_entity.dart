import 'dart:convert';
import 'package:flutter/material.dart';

abstract class StoredEntity {

    static const idFieldName = 'id';

    int _id;

    StoredEntity({ int id }): _id = id;

    int get id => _id;

    set id(int value) {
        _id = getIdFromValue(value, _id);
    }

    @protected
    int getIdFromValue(int value, int curId) => 
		curId == null && value != null ? value: curId;

    bool get isNew => _id == null;

    String get tableName;

    String get foreignTableName => null;

    @mustCallSuper
    Map<String, dynamic> toDbMap({ bool excludeIds }) => 
		(excludeIds ?? false) ? {}: { idFieldName: isNew ? null: id };

    String get tableExpr {
        const keyClause = '$idFieldName INTEGER PRIMARY KEY AUTOINCREMENT';

        return """CREATE TABLE IF NOT EXISTS $tableName (
            $keyClause,
            $columnsExpr
        );""";
    }

	List<String> getUpgradeExpr(int oldVersion) => [];

    String get columnsExpr;

	String get textData;

	String toJson() => jsonEncode(toDbMap(excludeIds: true));
}
