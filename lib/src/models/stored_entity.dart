import 'package:flutter/material.dart';

abstract class StoredEntity {
    static const idFieldName = 'id';

    int _id;

    StoredEntity({ int id }): _id = id ?? 0;

    int get id => _id;

    set id(int value) {
        _id = getIdFromValue(value, _id);
    }

    @protected
    int getIdFromValue(int value, int curId) => curId == 0 && value > 0 ? value: curId;

    bool get isNew => _id == 0;

    String get tableName;

    String get foreignTableName => null;

    @mustCallSuper
    Map<String, dynamic> toDbMap() => { idFieldName: isNew ? null: id };

    String get tableExpr {
        const keyClause = '$idFieldName INTEGER PRIMARY KEY AUTOINCREMENT';

        return """CREATE TABLE $tableName (
            $keyClause,
            $columnsExpr
        );""";
    }

    String get columnsExpr;
}
