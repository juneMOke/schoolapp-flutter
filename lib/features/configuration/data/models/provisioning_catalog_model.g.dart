// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'provisioning_catalog_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProvisioningCatalogModel _$ProvisioningCatalogModelFromJson(
  Map<String, dynamic> json,
) => ProvisioningCatalogModel(
  version: json['version'] as String? ?? '',
  country: json['country'] as String? ?? '',
  cycles:
      (json['cycles'] as List<dynamic>?)
          ?.map((e) => CatalogCycleModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

CatalogCycleModel _$CatalogCycleModelFromJson(Map<String, dynamic> json) =>
    CatalogCycleModel(
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      periodType: json['periodType'] as String?,
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
      defaultSelected: json['defaultSelected'] as bool? ?? false,
      levels:
          (json['levels'] as List<dynamic>?)
              ?.map(
                (e) => CatalogLevelModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );

CatalogLevelModel _$CatalogLevelModelFromJson(
  Map<String, dynamic> json,
) => CatalogLevelModel(
  code: json['code'] as String? ?? '',
  name: json['name'] as String? ?? '',
  displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 0,
  defaultSelected: json['defaultSelected'] as bool? ?? false,
  defaultClassrooms: (json['defaultClassrooms'] as num?)?.toInt() ?? 1,
  sections:
      (json['sections'] as List<dynamic>?)
          ?.map((e) => CatalogSectionModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  warnings:
      (json['warnings'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

CatalogSectionModel _$CatalogSectionModelFromJson(Map<String, dynamic> json) =>
    CatalogSectionModel(
      officialCode: json['officialCode'] as String? ?? '',
      filiere: json['filiere'] as String?,
      filiereAbregee: json['filiereAbregee'] as String?,
      libelle: json['libelle'] as String? ?? '',
      codeOfficiel: json['codeOfficiel'] as String? ?? '',
      courseCount: (json['courseCount'] as num?)?.toInt() ?? 0,
    );
