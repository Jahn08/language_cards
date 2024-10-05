import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'language.dart';
import 'stored_entity.dart';
import 'stored_word.dart';

class StoredPack extends StoredEntity {
  static const entityName = 'Packs';

  static const nameFieldName = 'name';
  static const fromFieldName = 'from_lang';
  static const toFieldName = 'to_lang';
  static const studyDateFieldName = 'study_date';

  static const _cardsFieldName = 'cards';

  static const String _noneName = 'None';

  static final StoredPack none = new StoredPack(_noneName);

  final String name;

  final Language? from;

  final Language? to;

  DateTime? _studyDate;

  int _cardsNumber;

  StoredPack(this.name,
      {super.id, this.from, this.to, DateTime? studyDate, int? cardsNumber})
      : assert(from == null || to == null || from != to),
        _cardsNumber = _getNonNegativeNumber(cardsNumber),
        _studyDate = studyDate;

  DateTime? get studyDate => _studyDate;

  void setNowAsStudyDate() => _studyDate = DateTime.now();

  static int _getNonNegativeNumber(int? value) =>
      value == null || value < 0 ? 0 : value;

  StoredPack.fromDbMap(Map<String, dynamic> values)
      : this(values[nameFieldName] as String? ?? '',
            id: values[StoredEntity.idFieldName] as int?,
            from: values[fromFieldName] == null ? null : Language.values[values[fromFieldName] as int],
            to: values[toFieldName] == null ? null : Language.values[values[toFieldName] as int],
            studyDate: _tryParseDate(values[studyDateFieldName] as int?));

  static DateTime? _tryParseDate(int? value) => value == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true).toLocal();

  int get cardsNumber => _cardsNumber;

  set cardsNumber(int value) => _cardsNumber = _getNonNegativeNumber(value);

  bool get isNone => name == _noneName && id == null;

  @override
  Map<String, dynamic> toDbMap({bool? excludeIds}) {
    final map = super.toDbMap(excludeIds: excludeIds);
    map.addAll({
      nameFieldName: name,
      fromFieldName: from?.index,
      toFieldName: to?.index,
      studyDateFieldName: studyDate?.toUtc().millisecondsSinceEpoch
    });

    return map;
  }

  @override
  String get tableName => entityName;

  @override
  String get columnsExpr => """ $nameFieldName TEXT NOT NULL,
            $fromFieldName INTEGER NOT NULL,
            $toFieldName INTEGER NOT NULL""";

  @override
  List<String> getUpgradeExpr(int oldVersion) {
    final clauses = <String>[];

    if (oldVersion < 5)
      clauses.add(
          'ALTER TABLE $tableName ADD COLUMN $studyDateFieldName INT NULL');

    return clauses;
  }

  @override
  String get textData => name;

  String getLocalisedName(BuildContext context) =>
      isNone ? AppLocalizations.of(context)!.storedPackNonePackName : name;

  Map<String, dynamic> toJsonMap(List<StoredWord> cards) {
    final packProps = toDbMap(excludeIds: true);
    packProps[_cardsFieldName] = cards;

    return packProps;
  }

  static MapEntry<StoredPack, List<dynamic>> fromJsonMap(
          Map<String, dynamic> obj) =>
      new MapEntry(StoredPack.fromDbMap(obj),
          (obj[StoredPack._cardsFieldName] ?? []) as List<dynamic>);
}
