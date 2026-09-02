// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_code_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeeCodeModel _$FeeCodeModelFromJson(Map<String, dynamic> json) => FeeCodeModel(
  code: json['code'] as String? ?? '',
  label: json['label'] as String?,
  active: json['active'] as bool?,
  sortOrder: (json['sortOrder'] as num?)?.toInt(),
);

Map<String, dynamic> _$FeeCodeSectionInputModelToJson(
  FeeCodeSectionInputModel instance,
) => <String, dynamic>{
  'code': instance.code,
  'label': ?instance.label,
  'active': ?instance.active,
  'sortOrder': ?instance.sortOrder,
};

Map<String, dynamic> _$FeeCodeSectionsPayloadModelToJson(
  FeeCodeSectionsPayloadModel instance,
) => <String, dynamic>{'sections': instance.sections};
