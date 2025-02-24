import 'package:flutter/material.dart';
import 'study_storage.dart';
import '../data/word_storage.dart';
import '../models/stored_entity.dart';
import '../models/stored_pack.dart';
import '../models/language.dart';

export '../models/stored_pack.dart';

class PackStorage extends BaseStorage<StoredPack> with StudyStorage {
  const PackStorage() : super();

  @override
  String get entityName => StoredPack.entityName;

  @override
  List<StoredPack> convertToEntity(List<Map<String, dynamic>> values) =>
      values.map((w) => new StoredPack.fromDbMap(w)).toList();

  @override
  Future<List<StoredPack>> fetch(
      {String? textFilter,
      int? skipCount,
      int? takeCount,
      LanguagePair? languagePair}) async {
    final packs = await fetchInternally(
        textFilter: textFilter,
        skipCount: skipCount,
        takeCount: takeCount,
        filters: _buildLanguagePairFilter(languagePair));

    final isFirstRequest = skipCount == null || skipCount == 0;
    if (textFilter == null && isFirstRequest) packs.insert(0, StoredPack.none);

    final lengths =
        await buildWordStorage().groupByParent(packs.map((p) => p.id).toList());
    packs.forEach((p) => p.cardsNumber = lengths[p.id] ?? 0);

    return packs;
  }

  static Map<String, List<int>>? _buildLanguagePairFilter(
      LanguagePair? languagePair) {
    return languagePair == null
        ? null
        : {
            StoredPack.fromFieldName: [languagePair.from.index],
            StoredPack.toFieldName: [languagePair.to.index]
          };
  }

  @protected
  WordStorage buildWordStorage() => const WordStorage();

  @override
  Future<List<StoredPack>> fetchInternally(
          {int? skipCount,
          List<String>? columns,
          int? takeCount,
          String? orderBy,
          String? textFilter,
          Map<String, List<dynamic>>? filters}) =>
      super.fetchInternally(
          columns: columns,
          skipCount: skipCount,
          takeCount: takeCount,
          orderBy: orderBy ?? StoredPack.nameFieldName,
          filters: filters,
          textFilter: textFilter);

  @override
  String get textFilterFieldName => StoredPack.nameFieldName;

  @override
  Future<StoredPack?> find(int? id) async {
    final pack = await super.find(id);

    if (pack != null) {
      final cardsNumber = await buildWordStorage().groupByParent([pack.id]);
      pack.cardsNumber = cardsNumber[pack.id] ?? 0;
    }

    return pack;
  }

  @override
  Future<List<StudyPack>> fetchStudyPacks(LanguagePair? languagePair) async {
    final packs =
        await fetchInternally(filters: _buildLanguagePairFilter(languagePair));
    final packMap = <int?, StoredPack>{
      for (final StoredPack p in packs) p.id: p
    };

    return (await buildWordStorage().groupByStudyLevels())
        .entries
        .where((e) => e.key != null && packMap.containsKey(e.key))
        .map((e) => new StudyPack(packMap[e.key]!, e.value))
        .toList();
  }

  Future<Set<LanguagePair>> fetchLanguagePairs() async {
    final groups = await connection.groupBySeveral(entityName,
        groupFields: [StoredPack.fromFieldName, StoredPack.toFieldName]);
    return groups.where((gr) => gr[StoredPack.fromFieldName] != null).map((gr) {
      return LanguagePair.fromDbMap(gr.fields);
    }).toSet();
  }

  Future<List<int?>> fetchIdsByLanguagePair(LanguagePair languagePair) async {
    final packs = await fetchInternally(
        columns: [StoredEntity.idFieldName],
        filters: _buildLanguagePairFilter(languagePair));

    return packs.map((p) => p.id).toList();
  }

  Future<Map<String, List<LanguagePair>>> groupLanguagePairsByNames() async {
    final groups = await connection.groupBySeveral(entityName, groupFields: [
      StoredPack.nameFieldName,
      StoredPack.fromFieldName,
      StoredPack.toFieldName
    ]);

    final packLangPairsByNames = <String, List<LanguagePair>>{};
    groups.where((gr) => gr[StoredPack.fromFieldName] != null).forEach((gr) {
      final langPair = LanguagePair.fromDbMap(gr.fields);
      final packName = gr.fields[StoredPack.nameFieldName] as String;
      if (packLangPairsByNames.containsKey(packName))
        packLangPairsByNames[packName]!.add(langPair);
      else
        packLangPairsByNames[packName] = [langPair];
    });
    return packLangPairsByNames;
  }

  Future<Map<String, int>> groupByTextIndexAndLanguagePair(
          [LanguagePair? languagePair]) =>
      groupByTextIndex(_buildLanguagePairFilter(languagePair));
}
