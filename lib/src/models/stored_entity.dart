import 'package:flutter/material.dart';

abstract class StoredEntity {
    int _id;

    StoredEntity({ int id }): _id = id ?? 0;

    int get id => _id;

    set id(int value) {
        _id = getIdFromValue(value, _id);
    }

    @protected
    int getIdFromValue(int value, int curId) => curId == 0 && value > 0 ? value: curId;
}
