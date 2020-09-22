import 'package:flutter/material.dart';
import './language.dart';
import './stored_entity.dart';

class StoredPack extends StoredEntity {
    final String name;

    final Language from;

    final Language to;

    final int cardsNumber;

    StoredPack(this.name, { int id, @required this.from, @required this.to, int cardsNumber }):
        cardsNumber = (cardsNumber ?? 0) > 0 ? cardsNumber : 0, 
        super(id: id) {
            assert(name != null);
            assert(from != null);
            assert(to != null);
            assert(from != to);
        }

    StoredPack.copy(StoredPack pack, { int cardsNumber }): 
        this(pack.name, id: pack.id, from: pack.from, to: pack.to, cardsNumber: cardsNumber);
}
