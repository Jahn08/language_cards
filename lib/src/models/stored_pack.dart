import 'package:flutter/material.dart';
import './language.dart';
import './stored_entity.dart';

class StoredPack extends StoredEntity {
    final String name;

    final Language from;

    final Language to;

    StoredPack(this.name, { int id, @required this.from, @required this.to }): 
        super(id: id) {
            assert(name != null);
            assert(from != null);
            assert(to != null);
            assert(from != to);
        }
}
