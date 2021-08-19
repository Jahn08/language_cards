import 'package:flutter/material.dart';
import 'study_storage.dart';
import '../data/base_storage.dart';
import '../data/word_storage.dart';
import '../models/study_pack.dart';
import '../models/stored_pack.dart';

export '../models/stored_pack.dart';

class PackStorage extends BaseStorage<StoredPack> with StudyStorage {

    @override
    String get entityName => StoredPack.entityName;

    @override
    List<StoredPack> convertToEntity(List<Map<String, dynamic>> values) => 
        values.map((w) => new StoredPack.fromDbMap(w)).toList();

    @override
    Future<List<StoredPack>> fetch({ String textFilter, int skipCount, int takeCount }) 
        async {
            final packs = await fetchInternally(
				textFilter: textFilter, skipCount: skipCount, takeCount: takeCount);

            final isFirstRequest = skipCount == null || skipCount == 0;
            if (textFilter == null && isFirstRequest)
                packs.insert(0, StoredPack.none);
			
            final lengths = await buildWordStorage().groupByParent(
                packs.map((p) => p.id).toList());
            packs.forEach((p) => p.cardsNumber = lengths[p.id]);

            return packs;
        }

	@protected
	WordStorage buildWordStorage() => new WordStorage();

	@override
    Future<List<StoredPack>> fetchInternally({ 
		int skipCount, int takeCount, String orderBy, String textFilter, 
		Map<String, List<dynamic>> filters 
	}) => super.fetchInternally(skipCount: skipCount, takeCount: takeCount,
		orderBy: orderBy ?? StoredPack.nameFieldName, filters: filters, textFilter: textFilter);
	
	@override
	String get textFilterFieldName => StoredPack.nameFieldName;

    @override
    Future<StoredPack> find(int id) async {
        final pack = await super.find(id);

        if (pack != null) {
            final cardsNumber = await buildWordStorage().groupByParent([pack.id]);
            pack.cardsNumber = cardsNumber[pack.id];
        }
        
        return pack;
    }

    @override
    Future<List<StudyPack>> fetchStudyPacks() async {
        final packs = await fetchInternally();
        final packMap = <int, StoredPack>{ for (StoredPack p in packs) p.id: p };
        
        return (await buildWordStorage().groupByStudyLevels())
            .entries.where((e) => e.key != null)
            .map((e) => new StudyPack(packMap[e.key], e.value)).toList();
    }
}
