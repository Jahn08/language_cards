import 'package:language_cards/src/models/part_of_speech.dart';
import '../data/base_storage.dart';
import '../data/db_provider.dart';
import '../models/stored_word.dart';
export '../models/stored_word.dart';
export '../data/base_storage.dart';

class WordStorage extends BaseStorage<StoredWord> {
  const WordStorage() : super();

  static int _dbVersionAfterUpdate = 0;

  @override
  String get entityName => StoredWord.entityName;

  Future<List<StoredWord>> findDuplicates(
      {required String text, PartOfSpeech? pos, int? id}) async {
    final foundWords = await fetchInternally(filters: {
      StoredWord.textFieldName: [text],
      StoredWord.partOfSpeechFieldName: [pos.toString()]
    });
    return id == null
        ? foundWords
        : foundWords.where((w) => w.id != id).toList();
  }

  Future<List<StoredWord>> fetchFiltered(
      {List<int?>? parentIds,
      List<int>? studyStageIds,
      String? text,
      int? skipCount,
      int? takeCount}) {
    final filters = <String, List<dynamic>>{};

    if (parentIds != null && parentIds.isNotEmpty)
      filters[_parentIdField] = parentIds;

    if (studyStageIds != null && studyStageIds.isNotEmpty)
      filters[StoredWord.studyProgressFieldName] = studyStageIds;

    return fetchInternally(
        skipCount: skipCount,
        takeCount: takeCount,
        filters: filters,
        textFilter: text);
  }

  @override
  Future<List<StoredWord>> fetch(
          {String? textFilter, int? skipCount, int? takeCount}) =>
      fetchInternally(
          textFilter: textFilter, takeCount: takeCount, skipCount: skipCount);

  @override
  Future<List<StoredWord>> fetchInternally(
      {int? skipCount,
      List<String>? columns,
      int? takeCount,
      String? orderBy,
      String? textFilter,
      Map<String, List<dynamic>>? filters}) async {
    await _normalizeTexts();

    return super.fetchInternally(
        skipCount: skipCount,
        takeCount: takeCount,
        orderBy: orderBy ?? StoredWord.normalTextFieldName,
        filters: filters,
        columns: columns,
        textFilter: textFilter);
  }

  Future _normalizeTexts() async {
    if (connection.versionBeforeUpdate == null ||
        _dbVersionAfterUpdate == DbProvider.normalTextFieldAddedVersion ||
        connection.versionBeforeUpdate! >= DbProvider.normalTextFieldAddedVersion)
      return;
    _dbVersionAfterUpdate = DbProvider.normalTextFieldAddedVersion;

    try {
      final cards =
          await super.fetchInternally(orderBy: StoredWord.textFieldName);
      await super.upsert(cards);
    } catch (_) {
      _dbVersionAfterUpdate = 0;
      rethrow;
    }
  }

  String get _parentIdField => StoredWord.packIdFieldName;

  @override
  String get textFilterFieldName => StoredWord.textFieldName;

  @override
  List<StoredWord> convertToEntity(List<Map<String, dynamic>> values) =>
      values.map((w) => new StoredWord.fromDbMap(w)).toList();

  @override
  Future<int> count({int? parentId, String? textFilter}) async {
    if (parentId == null) return super.count(textFilter: textFilter);

    return (await groupByParent([parentId], textFilter))[parentId]!;
  }

  Future<Map<int?, int>> groupByParent(
      [List<int?>? parentIds, String? textFilter]) async {
    final groups = await connection.groupBy(entityName,
        groupField: StoredWord.packIdFieldName,
        groupValues: parentIds,
        filters: addTextFilterClause(textFilter: textFilter));
    return <int?, int>{
      for (final g in groups) g[StoredWord.packIdFieldName] as int?: g.length
    };
  }

  Future<Map<int?, Map<int, int>>> groupByStudyLevels() async {
    final groups = await connection.groupBySeveral(entityName,
        groupFields: [_parentIdField, StoredWord.studyProgressFieldName]);

    return groups.fold<Map<int?, Map<int, int>>>(<int?, Map<int, int>>{},
        (res, gr) {
      final packId = gr[_parentIdField] as int?;
      if (!res.containsKey(packId)) res[packId] = <int, int>{};

      res[packId]![gr[StoredWord.studyProgressFieldName] as int] = gr.length;
      return res;
    });
  }

  Future<Map<String, int>> groupByTextIndexAndParent([List<int?>? parentIds]) =>
      groupByTextIndex(parentIds == null || parentIds.isEmpty
          ? null
          : {_parentIdField: parentIds});
}
