import './language.dart';
import './stored_entity.dart';

class StoredPack extends StoredEntity {
    static const entityName = 'Packs';

    static const nameFieldName = 'name';
    static const fromFieldName = 'from_lang';
    static const toFieldName = 'to_lang';
    static const cardsNumFieldName = 'cards_num';

    static const String noneName = 'None'; 

    static final StoredPack none = new StoredPack(noneName);

    final String name;

    final Language from;

    final Language to;

    int _cardsNumber;

    StoredPack(this.name, { int id, this.from, this.to, int cardsNumber }):
        _cardsNumber = _getNonNegativeNumber(cardsNumber),
        super(id: id) {
            assert(name != null);
            assert(from == null || to == null || from != to);
        }

    static int _getNonNegativeNumber(int value) => (value ?? 0) > 0 ? value : 0;

    StoredPack.fromDbMap(Map<String, dynamic> values):
        this(values[nameFieldName], 
            id: values[StoredEntity.idFieldName], 
            from: Language.values[values[fromFieldName]],
            to: Language.values[values[toFieldName]]);

    int  get cardsNumber => _cardsNumber;

    set cardsNumber(int value) => _cardsNumber = _getNonNegativeNumber(value);

    bool get isNone => name == noneName && id == null;

    @override
    Map<String, dynamic> toDbMap() {
        final map = super.toDbMap();
        map.addAll({
            nameFieldName: name,
            fromFieldName: from.index,
            toFieldName: to.index
        });

        return map;        
    }

    @override
    String get tableName => entityName;

    @override
    String get columnsExpr => 
        """ $nameFieldName TEXT NOT NULL,
            $fromFieldName INTEGER NOT NULL,
            $toFieldName INTEGER NOT NULL""";

	@override
	String get textData => this.name;
}
