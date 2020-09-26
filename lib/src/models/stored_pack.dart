import './language.dart';
import './stored_entity.dart';

class StoredPack extends StoredEntity {
    final String name;

    final Language from;

    final Language to;

    final int cardsNumber;

    StoredPack(this.name, { int id, this.from, this.to, int cardsNumber }):
        cardsNumber = (cardsNumber ?? 0) > 0 ? cardsNumber : 0, 
        super(id: id) {
            assert(name != null);
            assert(from == null || to == null || from != to);
        }

    StoredPack.copy(StoredPack pack, { int cardsNumber }): 
        this(pack.name, id: pack.id, from: pack.from, to: pack.to, cardsNumber: cardsNumber);
}
