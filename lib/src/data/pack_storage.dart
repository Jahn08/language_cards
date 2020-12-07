import '../data/base_storage.dart';
import '../data/word_storage.dart';
import '../models/stored_pack.dart';

export '../models/stored_pack.dart';

class PackStorage extends BaseStorage<StoredPack> {

    @override
    String get entityName => StoredPack.entityName;

    @override
    List<StoredPack> convertToEntity(List<Map<String, dynamic>> values) => 
        values.map((w) => new StoredPack.fromDbMap(w)).toList();

    @override
    Future<List<StoredPack>> fetch({ int skipCount, int takeCount, List<int> parentIds }) 
        async {
            final isFirstRequest = skipCount == null || skipCount == 0;
            if (isFirstRequest)
                takeCount = (takeCount ?? BaseStorage.itemsPerPageByDefault) - 1;

            final packs = await super.fetchInternally(skipCount: skipCount, takeCount: takeCount, 
                orderBy: StoredPack.nameFieldName);

            if (isFirstRequest)
                packs.insert(0, StoredPack.none);

            final lengths = await new WordStorage().getLength(packs.map((p) => p.id).toList());
            packs.forEach((p) => p.cardsNumber = lengths[p.id]);

            return packs;
        }

    @override
    Future<StoredPack> find(int id) async {
        if (id <= 0)
            return null;

        final pack = await super.find(id);

        if (pack != null) {
            final cardsNumber = await new WordStorage().getLength([pack.id]);
            pack.cardsNumber = cardsNumber[pack.id];
        }
        
        return pack;
    }
}
