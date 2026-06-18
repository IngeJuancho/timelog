// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetStudyModelCollection on Isar {
  IsarCollection<StudyModel> get studyModels => this.collection();
}

const StudyModelSchema = CollectionSchema(
  name: r'StudyModel',
  id: 742453653029790294,
  properties: {
    r'date': PropertySchema(
      id: 0,
      name: r'date',
      type: IsarType.dateTime,
    ),
    r'isTemplate': PropertySchema(
      id: 1,
      name: r'isTemplate',
      type: IsarType.bool,
    ),
    r'mode': PropertySchema(
      id: 2,
      name: r'mode',
      type: IsarType.byte,
      enumMap: _StudyModelmodeEnumValueMap,
    ),
    r'name': PropertySchema(
      id: 3,
      name: r'name',
      type: IsarType.string,
    ),
    r'templateSteps': PropertySchema(
      id: 4,
      name: r'templateSteps',
      type: IsarType.stringList,
    ),
    r'times': PropertySchema(
      id: 5,
      name: r'times',
      type: IsarType.objectList,
      target: r'TimeRecord',
    )
  },
  estimateSize: _studyModelEstimateSize,
  serialize: _studyModelSerialize,
  deserialize: _studyModelDeserialize,
  deserializeProp: _studyModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {r'TimeRecord': TimeRecordSchema},
  getId: _studyModelGetId,
  getLinks: _studyModelGetLinks,
  attach: _studyModelAttach,
  version: '3.1.0+1',
);

int _studyModelEstimateSize(
  StudyModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.templateSteps.length * 3;
  {
    for (var i = 0; i < object.templateSteps.length; i++) {
      final value = object.templateSteps[i];
      bytesCount += value.length * 3;
    }
  }
  bytesCount += 3 + object.times.length * 3;
  {
    final offsets = allOffsets[TimeRecord]!;
    for (var i = 0; i < object.times.length; i++) {
      final value = object.times[i];
      bytesCount += TimeRecordSchema.estimateSize(value, offsets, allOffsets);
    }
  }
  return bytesCount;
}

void _studyModelSerialize(
  StudyModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDateTime(offsets[0], object.date);
  writer.writeBool(offsets[1], object.isTemplate);
  writer.writeByte(offsets[2], object.mode.index);
  writer.writeString(offsets[3], object.name);
  writer.writeStringList(offsets[4], object.templateSteps);
  writer.writeObjectList<TimeRecord>(
    offsets[5],
    allOffsets,
    TimeRecordSchema.serialize,
    object.times,
  );
}

StudyModel _studyModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = StudyModel();
  object.date = reader.readDateTime(offsets[0]);
  object.id = id;
  object.isTemplate = reader.readBool(offsets[1]);
  object.mode =
      _StudyModelmodeValueEnumMap[reader.readByteOrNull(offsets[2])] ??
          StopwatchMode.regresoACero;
  object.name = reader.readString(offsets[3]);
  object.templateSteps = reader.readStringList(offsets[4]) ?? [];
  object.times = reader.readObjectList<TimeRecord>(
        offsets[5],
        TimeRecordSchema.deserialize,
        allOffsets,
        TimeRecord(),
      ) ??
      [];
  return object;
}

P _studyModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDateTime(offset)) as P;
    case 1:
      return (reader.readBool(offset)) as P;
    case 2:
      return (_StudyModelmodeValueEnumMap[reader.readByteOrNull(offset)] ??
          StopwatchMode.regresoACero) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readStringList(offset) ?? []) as P;
    case 5:
      return (reader.readObjectList<TimeRecord>(
            offset,
            TimeRecordSchema.deserialize,
            allOffsets,
            TimeRecord(),
          ) ??
          []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

const _StudyModelmodeEnumValueMap = {
  'regresoACero': 0,
  'continuo': 1,
};
const _StudyModelmodeValueEnumMap = {
  0: StopwatchMode.regresoACero,
  1: StopwatchMode.continuo,
};

Id _studyModelGetId(StudyModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _studyModelGetLinks(StudyModel object) {
  return [];
}

void _studyModelAttach(IsarCollection<dynamic> col, Id id, StudyModel object) {
  object.id = id;
}

extension StudyModelQueryWhereSort
    on QueryBuilder<StudyModel, StudyModel, QWhere> {
  QueryBuilder<StudyModel, StudyModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension StudyModelQueryWhere
    on QueryBuilder<StudyModel, StudyModel, QWhereClause> {
  QueryBuilder<StudyModel, StudyModel, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension StudyModelQueryFilter
    on QueryBuilder<StudyModel, StudyModel, QFilterCondition> {
  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> dateEqualTo(
      DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> dateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> dateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'date',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> dateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'date',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> isTemplateEqualTo(
      bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isTemplate',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> modeEqualTo(
      StopwatchMode value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'mode',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> modeGreaterThan(
    StopwatchMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'mode',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> modeLessThan(
    StopwatchMode value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'mode',
        value: value,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> modeBetween(
    StopwatchMode lower,
    StopwatchMode upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'mode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'templateSteps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'templateSteps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'templateSteps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'templateSteps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'templateSteps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'templateSteps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'templateSteps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'templateSteps',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'templateSteps',
        value: '',
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'templateSteps',
        value: '',
      ));
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'templateSteps',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'templateSteps',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'templateSteps',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'templateSteps',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'templateSteps',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      templateStepsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'templateSteps',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      timesLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> timesIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      timesIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      timesLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      timesLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition>
      timesLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'times',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension StudyModelQueryObject
    on QueryBuilder<StudyModel, StudyModel, QFilterCondition> {
  QueryBuilder<StudyModel, StudyModel, QAfterFilterCondition> timesElement(
      FilterQuery<TimeRecord> q) {
    return QueryBuilder.apply(this, (query) {
      return query.object(q, r'times');
    });
  }
}

extension StudyModelQueryLinks
    on QueryBuilder<StudyModel, StudyModel, QFilterCondition> {}

extension StudyModelQuerySortBy
    on QueryBuilder<StudyModel, StudyModel, QSortBy> {
  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> sortByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> sortByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> sortByIsTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTemplate', Sort.asc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> sortByIsTemplateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTemplate', Sort.desc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> sortByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> sortByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension StudyModelQuerySortThenBy
    on QueryBuilder<StudyModel, StudyModel, QSortThenBy> {
  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> thenByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.asc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> thenByDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'date', Sort.desc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> thenByIsTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTemplate', Sort.asc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> thenByIsTemplateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isTemplate', Sort.desc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> thenByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.asc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> thenByModeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'mode', Sort.desc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QAfterSortBy> thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension StudyModelQueryWhereDistinct
    on QueryBuilder<StudyModel, StudyModel, QDistinct> {
  QueryBuilder<StudyModel, StudyModel, QDistinct> distinctByDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'date');
    });
  }

  QueryBuilder<StudyModel, StudyModel, QDistinct> distinctByIsTemplate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isTemplate');
    });
  }

  QueryBuilder<StudyModel, StudyModel, QDistinct> distinctByMode() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'mode');
    });
  }

  QueryBuilder<StudyModel, StudyModel, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<StudyModel, StudyModel, QDistinct> distinctByTemplateSteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'templateSteps');
    });
  }
}

extension StudyModelQueryProperty
    on QueryBuilder<StudyModel, StudyModel, QQueryProperty> {
  QueryBuilder<StudyModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<StudyModel, DateTime, QQueryOperations> dateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'date');
    });
  }

  QueryBuilder<StudyModel, bool, QQueryOperations> isTemplateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isTemplate');
    });
  }

  QueryBuilder<StudyModel, StopwatchMode, QQueryOperations> modeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'mode');
    });
  }

  QueryBuilder<StudyModel, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<StudyModel, List<String>, QQueryOperations>
      templateStepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'templateSteps');
    });
  }

  QueryBuilder<StudyModel, List<TimeRecord>, QQueryOperations> timesProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'times');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetOperationTemplateCollection on Isar {
  IsarCollection<OperationTemplate> get operationTemplates => this.collection();
}

const OperationTemplateSchema = CollectionSchema(
  name: r'OperationTemplate',
  id: -3388506721230077640,
  properties: {
    r'name': PropertySchema(
      id: 0,
      name: r'name',
      type: IsarType.string,
    ),
    r'steps': PropertySchema(
      id: 1,
      name: r'steps',
      type: IsarType.stringList,
    )
  },
  estimateSize: _operationTemplateEstimateSize,
  serialize: _operationTemplateSerialize,
  deserialize: _operationTemplateDeserialize,
  deserializeProp: _operationTemplateDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {},
  embeddedSchemas: {},
  getId: _operationTemplateGetId,
  getLinks: _operationTemplateGetLinks,
  attach: _operationTemplateAttach,
  version: '3.1.0+1',
);

int _operationTemplateEstimateSize(
  OperationTemplate object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.name.length * 3;
  bytesCount += 3 + object.steps.length * 3;
  {
    for (var i = 0; i < object.steps.length; i++) {
      final value = object.steps[i];
      bytesCount += value.length * 3;
    }
  }
  return bytesCount;
}

void _operationTemplateSerialize(
  OperationTemplate object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.name);
  writer.writeStringList(offsets[1], object.steps);
}

OperationTemplate _operationTemplateDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = OperationTemplate();
  object.id = id;
  object.name = reader.readString(offsets[0]);
  object.steps = reader.readStringList(offsets[1]) ?? [];
  return object;
}

P _operationTemplateDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readStringList(offset) ?? []) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _operationTemplateGetId(OperationTemplate object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _operationTemplateGetLinks(
    OperationTemplate object) {
  return [];
}

void _operationTemplateAttach(
    IsarCollection<dynamic> col, Id id, OperationTemplate object) {
  object.id = id;
}

extension OperationTemplateQueryWhereSort
    on QueryBuilder<OperationTemplate, OperationTemplate, QWhere> {
  QueryBuilder<OperationTemplate, OperationTemplate, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension OperationTemplateQueryWhere
    on QueryBuilder<OperationTemplate, OperationTemplate, QWhereClause> {
  QueryBuilder<OperationTemplate, OperationTemplate, QAfterWhereClause>
      idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterWhereClause>
      idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterWhereClause>
      idGreaterThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterWhereClause>
      idLessThan(Id id, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterWhereClause>
      idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension OperationTemplateQueryFilter
    on QueryBuilder<OperationTemplate, OperationTemplate, QFilterCondition> {
  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      nameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      nameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      nameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      nameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      nameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      nameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsElementEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'steps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsElementGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'steps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsElementLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'steps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsElementBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'steps',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsElementStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'steps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsElementEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'steps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsElementContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'steps',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsElementMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'steps',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsElementIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'steps',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsElementIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'steps',
        value: '',
      ));
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'steps',
        length,
        true,
        length,
        true,
      );
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'steps',
        0,
        true,
        0,
        true,
      );
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'steps',
        0,
        false,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'steps',
        0,
        true,
        length,
        include,
      );
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'steps',
        length,
        include,
        999999,
        true,
      );
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterFilterCondition>
      stepsLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.listLength(
        r'steps',
        lower,
        includeLower,
        upper,
        includeUpper,
      );
    });
  }
}

extension OperationTemplateQueryObject
    on QueryBuilder<OperationTemplate, OperationTemplate, QFilterCondition> {}

extension OperationTemplateQueryLinks
    on QueryBuilder<OperationTemplate, OperationTemplate, QFilterCondition> {}

extension OperationTemplateQuerySortBy
    on QueryBuilder<OperationTemplate, OperationTemplate, QSortBy> {
  QueryBuilder<OperationTemplate, OperationTemplate, QAfterSortBy>
      sortByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterSortBy>
      sortByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension OperationTemplateQuerySortThenBy
    on QueryBuilder<OperationTemplate, OperationTemplate, QSortThenBy> {
  QueryBuilder<OperationTemplate, OperationTemplate, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterSortBy>
      thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterSortBy>
      thenByName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.asc);
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QAfterSortBy>
      thenByNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'name', Sort.desc);
    });
  }
}

extension OperationTemplateQueryWhereDistinct
    on QueryBuilder<OperationTemplate, OperationTemplate, QDistinct> {
  QueryBuilder<OperationTemplate, OperationTemplate, QDistinct> distinctByName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'name', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<OperationTemplate, OperationTemplate, QDistinct>
      distinctBySteps() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'steps');
    });
  }
}

extension OperationTemplateQueryProperty
    on QueryBuilder<OperationTemplate, OperationTemplate, QQueryProperty> {
  QueryBuilder<OperationTemplate, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<OperationTemplate, String, QQueryOperations> nameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'name');
    });
  }

  QueryBuilder<OperationTemplate, List<String>, QQueryOperations>
      stepsProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'steps');
    });
  }
}

// **************************************************************************
// IsarEmbeddedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

const TimeRecordSchema = Schema(
  name: r'TimeRecord',
  id: -6437961634876736518,
  properties: {
    r'cumulativeTime': PropertySchema(
      id: 0,
      name: r'cumulativeTime',
      type: IsarType.long,
    ),
    r'name': PropertySchema(
      id: 1,
      name: r'name',
      type: IsarType.string,
    ),
    r'stepIndex': PropertySchema(
      id: 2,
      name: r'stepIndex',
      type: IsarType.long,
    ),
    r'time': PropertySchema(
      id: 3,
      name: r'time',
      type: IsarType.long,
    ),
    r'type': PropertySchema(
      id: 4,
      name: r'type',
      type: IsarType.string,
    )
  },
  estimateSize: _timeRecordEstimateSize,
  serialize: _timeRecordSerialize,
  deserialize: _timeRecordDeserialize,
  deserializeProp: _timeRecordDeserializeProp,
);

int _timeRecordEstimateSize(
  TimeRecord object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.name;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  {
    final value = object.type;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _timeRecordSerialize(
  TimeRecord object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeLong(offsets[0], object.cumulativeTime);
  writer.writeString(offsets[1], object.name);
  writer.writeLong(offsets[2], object.stepIndex);
  writer.writeLong(offsets[3], object.time);
  writer.writeString(offsets[4], object.type);
}

TimeRecord _timeRecordDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = TimeRecord();
  object.cumulativeTime = reader.readLongOrNull(offsets[0]);
  object.name = reader.readStringOrNull(offsets[1]);
  object.stepIndex = reader.readLongOrNull(offsets[2]);
  object.time = reader.readLongOrNull(offsets[3]);
  object.type = reader.readStringOrNull(offsets[4]);
  return object;
}

P _timeRecordDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readLongOrNull(offset)) as P;
    case 1:
      return (reader.readStringOrNull(offset)) as P;
    case 2:
      return (reader.readLongOrNull(offset)) as P;
    case 3:
      return (reader.readLongOrNull(offset)) as P;
    case 4:
      return (reader.readStringOrNull(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

extension TimeRecordQueryFilter
    on QueryBuilder<TimeRecord, TimeRecord, QFilterCondition> {
  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      cumulativeTimeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'cumulativeTime',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      cumulativeTimeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'cumulativeTime',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      cumulativeTimeEqualTo(int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cumulativeTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      cumulativeTimeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cumulativeTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      cumulativeTimeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cumulativeTime',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      cumulativeTimeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cumulativeTime',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'name',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'name',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'name',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'name',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> nameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'name',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      stepIndexIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'stepIndex',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      stepIndexIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'stepIndex',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> stepIndexEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'stepIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition>
      stepIndexGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'stepIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> stepIndexLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'stepIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> stepIndexBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'stepIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> timeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'time',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> timeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'time',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> timeEqualTo(
      int? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'time',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> timeGreaterThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'time',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> timeLessThan(
    int? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'time',
        value: value,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> timeBetween(
    int? lower,
    int? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'time',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'type',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'type',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'type',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'type',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'type',
        value: '',
      ));
    });
  }

  QueryBuilder<TimeRecord, TimeRecord, QAfterFilterCondition> typeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'type',
        value: '',
      ));
    });
  }
}

extension TimeRecordQueryObject
    on QueryBuilder<TimeRecord, TimeRecord, QFilterCondition> {}
