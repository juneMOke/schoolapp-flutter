// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provisioning_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Map<String, dynamic> _$ProvisioningRequestModelToJson(
  ProvisioningRequestModel instance,
) => <String, dynamic>{
  'academicYear': instance.academicYear.toJson(),
  'defaultClassroomsPerLevel': ?instance.defaultClassroomsPerLevel,
  'cycles': instance.cycles.map((e) => e.toJson()).toList(),
  'fees': instance.fees.map((e) => e.toJson()).toList(),
};

Map<String, dynamic> _$AcademicYearInputModelToJson(
  AcademicYearInputModel instance,
) => <String, dynamic>{
  'name': instance.name,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'current': instance.current,
};

Map<String, dynamic> _$CycleInputModelToJson(CycleInputModel instance) =>
    <String, dynamic>{
      'catalogCode': instance.catalogCode,
      'levels': instance.levels.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$LevelInputModelToJson(LevelInputModel instance) =>
    <String, dynamic>{
      'catalogCode': instance.catalogCode,
      'classrooms': ?instance.classrooms,
      'sections': ?instance.sections?.map((e) => e.toJson()).toList(),
    };

Map<String, dynamic> _$SectionInputModelToJson(SectionInputModel instance) =>
    <String, dynamic>{
      'officialCode': instance.officialCode,
      'classrooms': instance.classrooms,
    };

Map<String, dynamic> _$FeeInputModelToJson(FeeInputModel instance) =>
    <String, dynamic>{
      'feeCode': instance.feeCode,
      'label': instance.label,
      'amountInCents': instance.amountInCents,
      'currency': instance.currency,
      'dueAt': ?instance.dueAt,
      'appliesTo': instance.appliesTo.toJson(),
    };

Map<String, dynamic> _$FeeScopeInputModelToJson(FeeScopeInputModel instance) =>
    <String, dynamic>{
      'scope': instance.scope,
      'levelCatalogCodes': ?instance.levelCatalogCodes,
    };
